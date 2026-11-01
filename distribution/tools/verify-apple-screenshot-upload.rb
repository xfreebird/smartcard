#!/usr/bin/env ruby
# Read back screenshot states, story order and exact uploaded-file checksums.
require 'spaceship'
require 'json'
require 'digest'
require 'pathname'
platform, directory = ARGV
abort 'Usage: bundle exec ruby distribution/tools/verify-apple-screenshot-upload.rb ios|macos PACK' unless %w[ios macos].include?(platform) && directory
pack = Pathname(directory)
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(key_id: ENV.fetch('ASC_KEY_ID'), issuer_id: ENV.fetch('ASC_ISSUER_ID'), filepath: ENV.fetch('ASC_KEY_PATH'))
app = Spaceship::ConnectAPI::App.find(platform == 'ios' ? 'md.esemnbun.ios' : 'md.esemnbun.mac')
version = app.get_app_store_versions.find { |v| v.version_string == '0.2.0' }
abort 'No 0.2.0 version' unless version
locales = { 'ro' => 'ro', 'en-US' => 'en', 'ru' => 'ru' }
locales['en-GB'] = 'en' if platform == 'macos'
translations = version.get_app_store_version_localizations
abort 'Missing localized draft' unless (locales.keys - translations.map(&:locale)).empty?
reports = []
locales.each do |locale, language|
  families = platform == 'ios' ? { 'iphone'=>'APP_IPHONE_67', 'ipad'=>'APP_IPAD_PRO_3GEN_129', 'duo-compact'=>'APP_IPHONE_DUO', 'duo-expanded'=>'APP_IPHONE_DUO' } : { 'macos'=>'APP_DESKTOP' }
  expected = Hash.new { |hash, key| hash[key] = {} }
  families.each do |family, type|
    folder = family.start_with?('duo-') ? 'supplemental' : 'screenshots'
    files = pack.join('apple', folder, language, family).glob('*.png').sort
    abort "Incomplete local screenshots: #{language}/#{family}" unless files.size == (family == 'macos' ? 6 : 5)
    files.each { |file| expected[type]["#{family}-#{file.basename}"] = Digest::MD5.file(file).hexdigest }
  end
  sets = translations.find { |translation| translation.locale == locale }.get_app_screenshot_sets
  expected.each do |type, hashes|
    set = sets.find { |candidate| candidate.screenshot_display_type == type }
    images = set&.app_screenshots || []
    state_ok = images.all? { |image| image.asset_delivery_state['state'] == 'COMPLETE' }
    ordered = images.map(&:file_name) == hashes.keys.sort
    exact = images.size == hashes.size && images.all? { |image| hashes[image.file_name] == image.source_file_checksum.to_s.downcase }
    mismatches = images.reject { |image| hashes[image.file_name] == image.source_file_checksum.to_s.downcase }.map(&:file_name)
    report = { locale: locale, type: type, count: images.size, states: images.map { |image| image.asset_delivery_state['state'] }, ordered: ordered, checksumsMatch: exact, checksumMismatches: mismatches, passed: state_ok && ordered && exact }
    reports << report
    puts JSON.generate(report)
  end
end
pack.join('upload').mkpath
pack.join('upload', "apple-#{platform}-screenshot-verification.json").write(JSON.pretty_generate(reports) + "\n")
abort 'Screenshot verification incomplete; see states, order and checksums above' unless reports.all? { |report| report[:passed] }
