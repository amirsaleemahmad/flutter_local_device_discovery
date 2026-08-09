#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_local_device_discovery_darwin.podspec` to validate.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_local_device_discovery_darwin'
  s.version          = '0.2.0'
  s.summary          = 'Apple platform implementation of flutter_local_device_discovery.'
  s.description      = <<-DESC
Apple platform implementation of flutter_local_device_discovery for iOS and macOS.
                       DESC
  s.homepage         = 'https://github.com/amirsaleemahmad/flutter_local_device_discovery'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aamir Saleem Ahmad' => 'amirsaleemahmad@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_local_device_discovery_darwin/Sources/flutter_local_device_discovery_darwin/**/*'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
