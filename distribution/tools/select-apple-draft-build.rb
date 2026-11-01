#!/usr/bin/env ruby
# Attach a processed build to an editable version; never submit it for review.
require 'spaceship'
platform, number = ARGV
abort 'Usage: select-apple-draft-build.rb ios|macos BUILD_NUMBER' unless %w[ios macos].include?(platform) && number&.match?(/\A[1-9][0-9]*\z/)
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
  key_id: ENV.fetch('ASC_KEY_ID'), issuer_id: ENV.fetch('ASC_ISSUER_ID'),
  key: File.read(ENV.fetch('ASC_KEY_PATH')))
identifier = platform == 'macos' ? 'md.esemnbun.mac' : 'md.esemnbun.ios'
api_platform = platform == 'macos' ? 'MAC_OS' : 'IOS'
app = Spaceship::ConnectAPI::App.find(identifier)
version = app.get_edit_app_store_version(platform: api_platform)
abort 'No editable version' unless version && version.app_store_state == 'PREPARE_FOR_SUBMISSION'
build = Spaceship::ConnectAPI::Build.all(app_id: app.id, build_number: number, platform: api_platform).find { |b| b.version == number }
abort 'Build is not processed yet' unless build && build.processing_state == 'VALID'
abort 'Marketing version differs' unless build.app_version == version.version_string
build.update(attributes: { usesNonExemptEncryption: false }) if build.uses_non_exempt_encryption.nil?
version.select_build(build_id: build.id)
abort 'Build selection verification failed' unless version.get_build.id == build.id
puts "#{identifier}: selected build #{number} for #{version.version_string} (#{version.app_store_state})"
