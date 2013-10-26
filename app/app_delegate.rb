class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = RubyisTokeiViewController.alloc.init
    @window.rootViewController.wantsFullScreenLayout = true
    @window.makeKeyAndVisible
    true
  end
end

class RubyisTokeiViewController < UIViewController
  #def loadView
  #  #self.view = UIImageView.alloc.init
  #  self.view = UIView.alloc.initWithFrame(UIScreen.mainScreen.bounds)
  #end

  def loadView
    url = ""
    @photo = RTPhoto.alloc.initWithPhoto(url)
    self.view = @photo
  end

  def viewDidLoad
    margin = 20

    @state = UILabel.new
    @state.font = UIFont.systemFontOfSize(30)
    @state.text = 'Tap to start'
    #@state.textAlignment = UITextAlignmentCenter
    @state.textColor = UIColor.whiteColor
    @state.backgroundColor = UIColor.clearColor
    @state.frame = [[margin, 200], [view.frame.size.width - margin * 2, 40]]
    self.view.addSubview(@state)


    #@photo.photoRect
    #view.addSubview(@state)
    #@clock = Clock.new
    #view.addSubview(@clock)
  end
end

class RTPhoto < UIImageView
  def initWithPhoto(url)
    photo = self.initWithFrame([[0,0], [568,320]])
    image = UIImage.imageNamed('ko1.jpg')
    self.contentMode = UIViewContentModeScaleAspectFit
    self.image = image

    @textarea = RTTextarea.new
    addSubview @textarea
    @textarea.setNeedsLayout
    photo
  end
end

class RTTextarea < UIView
  def init
    super.tap {|s|
      s.backgroundColor = UIColor.blackColor.colorWithAlphaComponent(0.7)
    }
  end

  def textareaHeight
    # XXX: auto calc
    60
  end

  def setNeedsLayout
    if superview
      frame = AVMakeRectWithAspectRatioInsideRect(superview.image.size, superview.bounds);
      origin = frame.origin
      size = frame.size
      origin.y = size.height - textareaHeight
      size.height = textareaHeight

      frame.origin = origin
      frame.size = size
      self.frame = frame
    end
  end
end

class RTTokei < UILabel
  CLOCK_FORMAT = "%H %M"

  def initialize
    self.font = UIFont.systemFontOfSize(100)
    self.textAlignment = UITextAlignmentCenter
    self.textColor = UIColor.whiteColor
    self.backgroundColor = UIColor.clearColor
    self.frame = [[0, 0], [200, 200]]
    self.text = "AAAAAAAAAAA"
  end
end
