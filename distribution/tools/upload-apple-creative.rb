#!/usr/bin/env ruby
# Upload one aspect-specific asset per Apple placement on the editable iOS draft; never submits for review.
require 'spaceship'
require 'net/http'
require 'json'
require 'digest'
require 'pathname'

args = ARGV.dup
replace_existing = args.delete('--replace-existing') != nil
abort 'Usage: upload-apple-creative.rb PACK [ro,en,ru] [--replace-existing]' if args.empty? || args.size > 2
pack = Pathname(args.fetch(0)).expand_path
locales = args.fetch(1, 'ro,en,ru').split(',')
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
  raise "Apple API #{method} #{path.split('?').first}: #{response.code} #{response.body.to_s[0,500]}" unless response.is_a?(Net::HTTPSuccess)
  response.body.to_s.empty? ? {} : JSON.parse(response.body)
end

def collection(path)
  values = []
  loop do
    response = api('get', path)
    values.concat(response.fetch('data'))
    following = response.dig('links', 'next')
    break unless following
    uri = URI(following)
    raise 'Unexpected Apple pagination origin' unless uri.scheme == 'https' && uri.host == 'api.appstoreconnect.apple.com'
    path = uri.request_uri
  end
  values
end

def upload_asset(library, path, locale, layout)
  bytes = path.binread
  name = "#{locale}-#{layout}-#{Digest::SHA256.hexdigest(bytes)[0,12]}.png"
  asset = collection("/v1/appAssetLibraries/#{library}/images?limit=200").find { |item| item.dig('attributes', 'fileName') == name }
  unless asset
    asset = api('post', '/v1/appAssetLibraryImages', data: {
      type: 'appAssetLibraryImages',
      attributes: { fileName: name, fileSize: bytes.bytesize, category: 'CREATIVE_ASSETS', referenceName: "eSemnBun #{layout} card signing — #{locale} — #{Digest::SHA256.hexdigest(bytes)[0,8]}" },
      relationships: { assetLibrary: { data: { type: 'appAssetLibraries', id: library } } }
    }).fetch('data')
    asset.fetch('attributes').fetch('uploadOperations').each do |operation|
      uri = URI(operation.fetch('url'))
      request = Net::HTTP.const_get(operation.fetch('method').capitalize).new(uri)
      operation.fetch('requestHeaders').each { |header| request[header.fetch('name')] = header.fetch('value') }
      request.body = bytes.byteslice(operation.fetch('offset'), operation.fetch('length'))
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 180) { |h| h.request(request) }
      abort "Apple asset upload HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    end
    api('patch', "/v1/appAssetLibraryImages/#{asset['id']}", data: { type: 'appAssetLibraryImages', id: asset['id'], attributes: { uploaded: true } })
  end
  180.times do |attempt|
    asset = api('get', "/v1/appAssetLibraryImages/#{asset['id']}").fetch('data')
    state = asset.dig('attributes', 'state')
    puts JSON.generate(locale: locale, layout: layout, assetId: asset['id'], processingState: state) if (attempt % 20).zero?
    break if %w[PREPARE_FOR_SUBMISSION APPROVED].include?(state)
    abort "Asset processing failed: #{asset.dig('attributes', 'stateDetails')}" if %w[FAILED REJECTED].include?(state)
    sleep 3
  end
  abort 'Asset not ready for placement' unless %w[PREPARE_FOR_SUBMISSION APPROVED].include?(asset.dig('attributes', 'state'))
  [asset, bytes, name]
end

app = Spaceship::ConnectAPI::App.find('md.esemnbun.ios')
version = app.get_edit_app_store_version(platform: 'IOS')
abort 'No editable iOS App Store version' unless version
translations = version.get_app_store_version_localizations
library = api('get', "/v1/apps/#{app.id}/assetLibrary").fetch('data').fetch('id')
reference = api('get', '/v1/appAssetLibraryRefData').fetch('data').first.fetch('attributes')
policies = reference.fetch('features').find { |feature| feature['featureId'] == 'APP_STORE_VERSIONS' }.fetch('placementPolicies')
placements = {
  'PRODUCT_PAGE_HEADER_ASSET' => ['header', 'header-reader-signing.png'],
  'APP_STORE_SEARCH_RESULTS_ASSET' => ['search-results', 'search-results-reader-signing.png']
}
creative = pack.join('apple/creative')
manifest = creative.join('manifest.json')
asset_paths = {}
if manifest.file?
  JSON.parse(manifest.read).each do |entry|
    entry.fetch('placements').each do |type|
      key = [entry.fetch('locale'), type]
      abort "Duplicate artwork for #{key.join('/')}" if asset_paths.key?(key)
      path = creative.join(entry.fetch('path')).cleanpath
      abort "Artwork outside creative directory: #{path}" unless path.to_s.start_with?(creative.to_s + '/')
      abort "Missing or changed artwork: #{path}" unless path.file? && Digest::SHA256.file(path).hexdigest == entry.fetch('sha256')
      asset_paths[key] = path
    end
  end
end
placements.each_key do |type|
  abort "Unsupported #{type}" unless policies.any? { |policy| policy['placementType'] == type && policy['groupLimits'].any? { |group| group['groupIds'].include?('DEFAULT_PROFILE') } }
end

receipts = []
locales.each do |locale|
  translation = translations.find { |item| item.locale == (locale == 'en' ? 'en-US' : locale) }
  abort "Missing localization #{locale}" unless translation
  current = collection("/v1/appStoreVersionLocalizations/#{translation.id}/placements?include=image&limit=200")
  placements.each do |type, (layout, file_name)|
    path = if manifest.file?
             asset_paths.fetch([locale, type]) { abort "Missing artwork for #{locale}/#{type}" }
           else
             creative.join(locale, file_name)
           end
    abort "Missing #{path}" unless path.file?
    asset, bytes, stored_name = upload_asset(library, path, locale, layout)
    old = current.find { |item| item.dig('attributes', 'placementType') == type }
    payload = { data: { type: 'appAssetLibraryPlacements', attributes: { placementType: type, placementGroup: 'DEFAULT_PROFILE' }, relationships: {
      image: { data: { type: 'appAssetLibraryImages', id: asset['id'] } },
      appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: translation.id } }
    } } }
    if old && old.dig('relationships', 'image', 'data', 'id') != asset['id']
      abort "Existing #{locale}/#{type} uses another image; pass --replace-existing for an authorized replacement" unless replace_existing
      prior_id = old.dig('relationships', 'image', 'data', 'id')
      api('delete', "/v1/appAssetLibraryPlacements/#{old['id']}")
      begin
        placement = api('post', '/v1/appAssetLibraryPlacements', payload).fetch('data')
      rescue StandardError => failure
        rollback = Marshal.load(Marshal.dump(payload)); rollback[:data][:relationships][:image][:data][:id] = prior_id
        api('post', '/v1/appAssetLibraryPlacements', rollback)
        raise failure
      end
    else
      placement = old || api('post', '/v1/appAssetLibraryPlacements', payload).fetch('data')
    end
    verified = api('get', "/v1/appAssetLibraryPlacements/#{placement['id']}?include=image").fetch('data')
    abort 'Placement read-back does not match artwork' unless verified.dig('relationships', 'image', 'data', 'id') == asset['id'] && verified.dig('attributes', 'placementType') == type
    receipt = { locale: locale, layout: layout, fileName: stored_name, sourceSha256: Digest::SHA256.hexdigest(bytes), assetId: asset['id'], assetState: asset.dig('attributes', 'state'), placementType: type, placementId: verified['id'], placementState: verified.dig('attributes', 'state') }
    receipts << receipt; puts JSON.generate(receipt)
  end
end
folder = pack.join('upload'); folder.mkpath
folder.join("apple-creative-receipt-#{locales.join('-')}.json").write(JSON.pretty_generate(receipts) + "\n")
