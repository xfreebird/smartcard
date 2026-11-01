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
unless app
  bundle = Spaceship::ConnectAPI::BundleId.find(identifier)
  abort "Missing registered identifier #{identifier}" unless bundle
  Spaceship::ConnectAPI::App.create(name: 'eSemnBun', version_string: '0.2.0', sku: identifier,
    primary_locale: 'en-US', bundle_id: bundle.id, platforms: [platform == 'ios' ? 'IOS' : 'MAC_OS'])
  app = Spaceship::ConnectAPI::App.find(identifier)
end
Dir.mktmpdir('esemnbun-apple-upload-') do |stage|
  %w[ro en ru].each do |locale|
    target = File.join(stage, locale == 'en' ? 'en-US' : locale)
    FileUtils.mkdir_p(target)
    families = platform == 'ios' ? %w[iphone ipad] : %w[macos]
    families.each do |family|
      Dir.glob(File.join(File.expand_path(pack), 'apple/screenshots', locale, family, '*.png')).sort.each do |file|
        FileUtils.cp(file, File.join(target, "#{family}-#{File.basename(file)}"))
      end
    end
  end
  options = FastlaneCore::Configuration.create(Deliver::Options.available_options, {
    api_key: key, app_identifier: identifier, app_version: '0.2.0',
    platform: platform == 'ios' ? 'ios' : 'osx',
    metadata_path: File.join(root, 'apple', platform), screenshots_path: stage,
    skip_binary_upload: true, submit_for_review: false, automatic_release: false,
    force: true, overwrite_screenshots: false, run_precheck_before_submit: false,
    app_review_information: { notes: File.read(File.join(root, 'apple/review_notes.txt')) },
    screenshot_processing_timeout: 600
  })
  Deliver::Runner.new(options).run
end
puts JSON.generate(appId: app.id, platform: platform, result: 'draft upload completed; not submitted')
