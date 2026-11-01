#!/usr/bin/env ruby
# Upload localized draft assets only; never submits or releases an app.
require 'spaceship'
require 'deliver'
require 'tmpdir'
require 'fileutils'
require 'json'
platform, pack = ARGV
abort 'Usage: bundle exec ruby distribution/tools/upload-apple-draft.rb ios|macos PACK' unless %w[ios macos].include?(platform) && pack
root = File.expand_path('..', __dir__)
key = { key_id: ENV.fetch('ASC_KEY_ID'), issuer_id: ENV.fetch('ASC_ISSUER_ID'), key: File.read(ENV.fetch('ASC_KEY_PATH')), in_house: false }
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(key_id: key[:key_id], issuer_id: key[:issuer_id], key: key[:key])
identifier = platform == 'ios' ? 'md.esemnbun.ios' : 'md.esemnbun.mac'
app = Spaceship::ConnectAPI::App.find(identifier)
abort "Create #{identifier} in App Store Connect first; Apple's public API cannot create app records" unless app
if platform == 'macos'
  # Separate bundle IDs need distinct localized Store names within this team.
  app.fetch_edit_app_info.get_app_info_localizations.each do |locale|
    locale.update(attributes: { name: 'eSemnBun for Mac' })
  end
end
Dir.mktmpdir('esemnbun-apple-upload-') do |stage|
  metadata = File.join(stage, 'metadata')
  FileUtils.cp_r(File.join(root, 'apple', platform), metadata)
  if platform == 'macos'
    FileUtils.cp_r(File.join(metadata, 'en-US'), File.join(metadata, 'en-GB'))
    Dir.glob(File.join(metadata, '*', 'name.txt')).each { |file| File.write(file, "eSemnBun for Mac\n") }
  end
  screenshots = File.join(stage, 'screenshots')
  %w[ro en ru].each do |locale|
    target = File.join(screenshots, locale == 'en' ? 'en-US' : locale)
    FileUtils.mkdir_p(target)
    families = platform == 'ios' ? %w[iphone ipad] : %w[macos]
    families.each do |family|
      Dir.glob(File.join(File.expand_path(pack), 'apple/screenshots', locale, family, '*.png')).sort.each do |file|
        FileUtils.cp(file, File.join(target, "#{family}-#{File.basename(file)}"))
      end
    end
  end
  FileUtils.cp_r(File.join(screenshots, 'en-US'), File.join(screenshots, 'en-GB')) if platform == 'macos'
  abort 'No screenshots found' if Dir.glob(File.join(screenshots, '**', '*.png')).empty?
  options = FastlaneCore::Configuration.create(Deliver::Options.available_options, {
    api_key: key, app_identifier: identifier, app_version: '0.2.0',
    platform: platform == 'ios' ? 'ios' : 'osx',
    metadata_path: metadata, screenshots_path: screenshots, copyright: '2026 Nicolae Ghimbovschi',
    skip_binary_upload: true, submit_for_review: false, automatic_release: false,
    force: true, overwrite_screenshots: false, run_precheck_before_submit: false,
    screenshot_processing_timeout: 600
  })
  if ENV['REVIEW_CONTACT_PHONE']
    options[:app_review_information] = { first_name: 'Nicolae', last_name: 'Ghimbovschi',
      email_address: 'nicolae.ghimbovschi@gmail.com', phone_number: ENV.fetch('REVIEW_CONTACT_PHONE'),
      notes: File.read(File.join(root, 'apple/review_notes.txt')) }
  end
  Deliver::Runner.new(options).run
end
puts JSON.generate(appId: app.id, platform: platform, result: 'draft upload completed; not submitted')
