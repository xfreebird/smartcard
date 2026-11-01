#!/usr/bin/env ruby
# Upload and place artwork in the editable iOS draft; never submit assets for review.
require 'spaceship'
require 'net/http'
require 'json'
require 'digest'
require 'pathname'
pack = Pathname(ARGV.fetch(0))
locales = ARGV.fetch(1, 'ro,en,ru').split(',')
abort 'Unsupported locale' unless (locales - %w[ro en ru]).empty?
TOKEN = Spaceship::ConnectAPI::Token.create(key_id: ENV.fetch('ASC_KEY_ID'), issuer_id: ENV.fetch('ASC_ISSUER_ID'), filepath: ENV.fetch('ASC_KEY_PATH'), duration: 1200)
Spaceship::ConnectAPI.token = TOKEN

def api(method, path, payload = nil)
  uri = URI('https://api.appstoreconnect.apple.com' + path)
  request = Net::HTTP.const_get(method.capitalize).new(uri)
  request['Authorization'] = 'Bearer ' + TOKEN.text
  request['Content-Type'] = 'application/json'
  request.body = JSON.generate(payload) if payload
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 180) { |h| h.request(request) }
  abort "Apple API #{method} #{path.split('?').first}: #{response.code} #{response.body[0,500]}" unless response.is_a?(Net::HTTPSuccess)
  response.body.empty? ? {} : JSON.parse(response.body)
end

app = Spaceship::ConnectAPI::App.find('md.esemnbun.ios')
version = app.get_app_store_versions.find { |v| v.version_string == '0.2.0' && v.app_store_state == 'PREPARE_FOR_SUBMISSION' }
abort 'No editable iOS 0.2.0 draft' unless version
translations = version.get_app_store_version_localizations
library = api('get', "/v1/apps/#{app.id}/assetLibrary").fetch('data').fetch('id')
reference = api('get', '/v1/appAssetLibraryRefData').fetch('data').first.fetch('attributes')
policies = reference.fetch('features').find { |f| f['featureId'] == 'APP_STORE_VERSIONS' }.fetch('placementPolicies')
placements = %w[PRODUCT_PAGE_HEADER_ASSET APP_STORE_SEARCH_RESULTS_ASSET]
placements.each { |type| abort "Unsupported #{type}" unless policies.any? { |p| p['placementType'] == type && p['groupLimits'].any? { |g| g['groupIds'].include?('DEFAULT_PROFILE') } } }
receipts = []
locales.each do |locale|
  path = pack.join('apple/creative', locale, 'reader-signing.png')
  abort "Missing #{path}" unless path.file?
  translation = translations.find { |t| t.locale == (locale == 'en' ? 'en-US' : locale) }
  abort "Missing localization #{locale}" unless translation
  bytes = path.binread
  name = "#{locale}-reader-signing-#{Digest::SHA256.hexdigest(bytes)[0,12]}.png"
  existing = api('get', "/v1/appAssetLibraries/#{library}/images?limit=200").fetch('data')
  asset = existing.find { |i| i.dig('attributes', 'fileName') == name }
  unless asset
    asset = api('post', '/v1/appAssetLibraryImages', data: { type: 'appAssetLibraryImages', attributes: { fileName: name, fileSize: bytes.bytesize, category: 'CREATIVE_ASSETS', referenceName: "eSemnBun wired reader signing — #{locale}" }, relationships: { assetLibrary: { data: { type: 'appAssetLibraries', id: library } } } }).fetch('data')
    asset.fetch('attributes').fetch('uploadOperations').each do |op|
      uri = URI(op.fetch('url'))
      request = Net::HTTP.const_get(op.fetch('method').capitalize).new(uri)
      op.fetch('requestHeaders').each { |header| request[header.fetch('name')] = header.fetch('value') }
      request.body = bytes.byteslice(op.fetch('offset'), op.fetch('length'))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 180) { |h| h.request(request) }
      abort "Apple asset upload HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    end
    api('patch', "/v1/appAssetLibraryImages/#{asset['id']}", data: { type: 'appAssetLibraryImages', id: asset['id'], attributes: { uploaded: true } })
  end
  180.times do |attempt|
    asset = api('get', "/v1/appAssetLibraryImages/#{asset['id']}").fetch('data')
    state = asset.dig('attributes', 'state')
    if attempt % 20 == 0
      puts JSON.generate(locale: locale, assetId: asset['id'], processingState: state)
      $stdout.flush
    end
    break if %w[PREPARE_FOR_SUBMISSION APPROVED].include?(state)
    abort "Asset processing failed: #{asset.dig('attributes', 'stateDetails')}" if %w[FAILED REJECTED].include?(state)
    sleep 3
  end
  abort 'Asset not ready for placement' unless %w[PREPARE_FOR_SUBMISSION APPROVED].include?(asset.dig('attributes', 'state'))
  current = api('get', "/v1/appStoreVersionLocalizations/#{translation.id}/placements?include=image&limit=200").fetch('data')
  placements.each do |type|
    old = current.find { |p| p.dig('attributes', 'placementType') == type }
    abort "Existing #{locale}/#{type} uses another image; review replacement explicitly" if old && old.dig('relationships', 'image', 'data', 'id') != asset['id']
    placement = old || api('post', '/v1/appAssetLibraryPlacements', data: { type: 'appAssetLibraryPlacements', attributes: { placementType: type, placementGroup: 'DEFAULT_PROFILE' }, relationships: { image: { data: { type: 'appAssetLibraryImages', id: asset['id'] } }, appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: translation.id } } } }).fetch('data')
    verified = api('get', "/v1/appAssetLibraryPlacements/#{placement['id']}?include=image").fetch('data')
    abort 'Placement read-back does not match artwork' unless verified.dig('relationships', 'image', 'data', 'id') == asset['id'] && verified.dig('attributes', 'placementType') == type
    receipt = { locale: locale, assetId: asset['id'], assetState: asset.dig('attributes','state'), placementType: type, placementId: verified['id'], placementState: verified.dig('attributes','state') }
    receipts << receipt
    puts JSON.generate(receipt)
    $stdout.flush
  end
end
folder = pack.join('upload'); folder.mkpath
folder.join("apple-creative-receipt-#{locales.join('-')}.json").write(JSON.pretty_generate(receipts) + "\n")
