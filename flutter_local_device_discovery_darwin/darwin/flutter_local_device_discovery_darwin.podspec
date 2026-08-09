#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
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
  s.source_files     = 'Sources/flutter_local_device_discovery_darwin/**/*.swift'
  s.platforms = { :ios => '12.0', :osx => '10.14' }
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
end