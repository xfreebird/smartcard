#!/usr/bin/env ruby
# Upload localized draft assets only; never submits or releases an app.
require 'spaceship'
require 'deliver'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'digest'
platform, pack, *flags = ARGV
abort "Unknown options: #{flags.join(' ')}" unless (flags - %w[--screenshots-only --replace-screenshots --replace-changed-screenshot-sets]).empty?
abort 'Usage: bundle exec ruby distribution/tools/upload-apple-draft.rb ios|macos PACK' unless %w[ios macos].include?(platform) && pack
root = File.expand_path('..', __dir__)
prepared_metadata = File.join(File.expand_path(pack), 'metadata', 'apple')
apple_metadata = File.directory?(File.join(prepared_metadata, platform)) ? prepared_metadata : File.join(root, 'apple')
key = { key_id: ENV.fetch('ASC_KEY_ID'), issuer_id: ENV.fetch('ASC_ISSUER_ID'), key: File.read(ENV.fetch('ASC_KEY_PATH')), in_house: false }
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(key_id: key[:key_id], issuer_id: key[:issuer_id], key: key[:key])
identifier = platform == 'ios' ? 'md.esemnbun.ios' : 'md.esemnbun.mac'
app = Spaceship::ConnectAPI::App.find(identifier)
abort "Create #{identifier} in App Store Connect first; Apple's public API cannot create app records" unless app
version = app.get_edit_app_store_version(platform: platform == 'ios' ? 'IOS' : 'MAC_OS')
abort "No editable #{platform} App Store version" unless version
Dir.mktmpdir('esemnbun-apple-upload-') do |stage|
  metadata = File.join(stage, 'metadata')
  FileUtils.cp_r(File.join(apple_metadata, platform), metadata)
  screenshots = File.join(stage, 'screenshots')
  %w[ro en ru].each do |locale|
    target = File.join(screenshots, locale == 'en' ? 'en-US' : locale)
    FileUtils.mkdir_p(target)
    families = platform == 'ios' ? %w[iphone ipad duo-compact duo-expanded] : %w[macos]
    families.each do |family|
      folder = family.start_with?('duo-') ? 'apple/supplemental' : 'apple/screenshots'
      Dir.glob(File.join(File.expand_path(pack), folder, locale, family, '*.png')).sort.each do |file|
        FileUtils.cp(file, File.join(target, "#{family}-#{File.basename(file)}"))
      end
    end
  end
  FileUtils.cp_r(File.join(screenshots, 'en-US'), File.join(screenshots, 'en-GB')) if platform == 'macos'
  abort 'No screenshots found' if Dir.glob(File.join(screenshots, '**', '*.png')).empty?
  if flags.include?('--replace-changed-screenshot-sets')
    abort 'Choose either full or changed-set replacement' if flags.include?('--replace-screenshots')
    version.get_app_store_version_localizations.each do |translation|
      files = Dir.glob(File.join(screenshots, translation.locale, '*.png'))
      desired = files.group_by { |file| Deliver::AppScreenshot.calculate_display_type(file) }
      translation.get_app_screenshot_sets.each do |set|
        paths = desired[set.screenshot_display_type]
        next unless paths
        expected = paths.map { |file| Digest::MD5.file(file).hexdigest }.sort
        current = set.app_screenshots.map { |image| image.source_file_checksum.to_s.downcase }.sort
        next if current == expected
        puts "Refreshing changed screenshot set: #{translation.locale}/#{set.screenshot_display_type}"
        set.delete!
      end
    end
  end
  options = FastlaneCore::Configuration.create(Deliver::Options.available_options, {
    api_key: key, app_identifier: identifier, app_version: version.version_string,
    platform: platform == 'ios' ? 'ios' : 'osx',
    metadata_path: metadata, screenshots_path: screenshots, copyright: '2026 Nicolae Ghimbovschi',
    skip_binary_upload: true, submit_for_review: false, automatic_release: false,
    skip_metadata: flags.include?('--screenshots-only'),
    force: true, overwrite_screenshots: flags.include?('--replace-screenshots'), run_precheck_before_submit: false,
    screenshot_processing_timeout: 600
  })
  if ENV['REVIEW_CONTACT_PHONE'] && !flags.include?('--screenshots-only')
    review_notes = platform == 'ios' ? 'ios/review-notes-nfc.txt' : 'review_notes.txt'
    options[:app_review_information] = { first_name: 'Nicolae', last_name: 'Ghimbovschi',
      email_address: 'nicolae.ghimbovschi@gmail.com', phone_number: ENV.fetch('REVIEW_CONTACT_PHONE'),
      notes: File.read(File.join(apple_metadata, review_notes)) }
  end
  Deliver::Runner.new(options).run
end
puts JSON.generate(appId: app.id, platform: platform, result: 'draft upload completed; not submitted')
