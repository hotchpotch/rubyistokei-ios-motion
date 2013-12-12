
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

require 'bubble-wrap/core'
require 'bubble-wrap/http'

desc 'generate icons'
task 'icons' do
  def echo_system(cmd)
    puts cmd
    system cmd
  end

  icon = 'resources/rubyistokei-app-icon.png'
  echo_system "convert #{icon} -geometry 152x152 resources/Icon-76@2x.png"
  echo_system "convert #{icon} -geometry 120x120 resources/Icon@2x.png"
  echo_system "convert #{icon} -geometry 76x76   resources/Icon-76.png"
  echo_system "convert #{icon} -geometry 80x80   resources/Icon-Small-40@2x.png"
  echo_system "convert #{icon} -geometry 40x40   resources/Icon-Small-40.png"
  echo_system "convert #{icon} -geometry 58x58   resources/Icon-Small@2x.png"
  echo_system "convert #{icon} -geometry 29x29   resources/Icon-Small.png"
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.version = '1.0.0'
  app.name = 'Rubyistokei'
  app.deployment_target = '7.0'
  app.identifier = "Rubyistokei"
  app.icons = %w(
    iTunesArtwork@2x.png
    Icon-76@2x.png
    Icon@2x.png
    Icon-76.png
    Icon-Small-40@2x.png
    Icon-Small-40.png
    Icon-Small@2x.png
    Icon-Small.png
  )
  app.info_plist['UIStatusBarHidden'] = true
  app.info_plist['UIViewControllerBasedStatusBarAppearance'] = false
  app.info_plist['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationLandscapeLeft']

  app.release do
    app.provisioning_profile = "#{ENV['HOME']}/Dropbox/iOS/mobileprovisions/Rubyistokei.mobileprovision"
    app.entitlements['aps-environment'] = 'production'
  end

  app.pods do
    pod 'GlitchKit', '= 0.0.2'
  end

  app.frameworks += ['AVFoundation']
end
