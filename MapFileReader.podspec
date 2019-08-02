Pod::Spec.new do |s|

s.name = "MapFileReader"
s.summary = "MapFileReader will be used to read Mapsforge map files."

s.version = "0.0.1"
s.license = { :type => "Proprietary", :file => "COPYING" }
s.author = { "calimoto GmbH" => "ios-team@calimoto.com" }
s.homepage = "https://calimoto.com"

s.platform = :ios
s.ios.deployment_target = '11.0'

s.source = { :git => "git@github.com:calimoto-GmbH/mapsforge-map-reader-ios.git",
:tag => s.version.to_s }

s.source_files = 'MapFileReader/**/*'
s.exclude_files = "MapFileReader/*.plist"

s.swift_version = "4.2"

end
