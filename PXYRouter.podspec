#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "PXYRouter"
  s.version          = "0.1.0"
  s.summary          = "URL Routing Library."
  s.description      = <<-DESC
                       PXYRouter is URL Routing Library.
                       DESC
  s.homepage         = "https://github.com/sora0077/PXYRouter"
  # s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "t.hayashi" => "t.hayashi0077+bitbucket@gmail.com" }
  s.source           = { :git => "https://github.com/sora0077/PXYRouter.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/EXAMPLE'

  s.platform     = :ios, '7.0'
  # s.ios.deployment_target = '5.0'
  # s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source_files = 'PXYRouter'
  s.dependency 'Aspects'
  # s.resources = 'Assets/*.png'

  # s.ios.exclude_files = 'Classes/osx'
  # s.osx.exclude_files = 'Classes/ios'
  # s.public_header_files = 'Classes/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end
