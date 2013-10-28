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
    textarea = super
    self.backgroundColor = UIColor.blackColor.colorWithAlphaComponent(0.7)
    textarea
  end

  def textareaHeight
    # XXX: auto calc
    60
  end

  def updateFontsLayout
    @name = UILabel.new
    @title = UILabel.new
    @bio = UILabel.new
    @taken_by = UILabel.new

    name = 'Koichi SASADA'
    font = UIFont.fontWithName("AvenirNext-Bold", size: 30)
    name_text_size = RTTextUtil.text(name, sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @name.font = font
    @name.textColor = UIColor.whiteColor
    @name.backgroundColor = UIColor.clearColor
    @name.text = name
    padding = 5
    @name.frame = [[padding, 0], name_text_size]
    addSubview(@name)

    title = '@koichisasada as a teacher'
    title_font_size = 16
    begin
      title_font = UIFont.fontWithName("AvenirNext-Regular", size: title_font_size)
      title_font_size -= 1
      title_text_size = RTTextUtil.text(title, sizeWithFont: title_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
      # XXX: name のサイズが frame より大きかった場合バグる
    end while name_text_size.width + padding * 3 + title_text_size.width > frame.size.width
    @title.font = title_font
    @title.textColor = UIColor.whiteColor
    @title.backgroundColor = UIColor.clearColor
    @title.text = title
    @title.frame = [[name_text_size.width + padding * 2, name_text_size.height - title_text_size.height - padding],
                    title_text_size]
    addSubview(@title)
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

      updateFontsLayout
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

class RTTextUtil
  def self.text(text, sizeWithFont:font, constrainedToSize:size, lineBreakMode:lineBreakMode)
    if false # UIDevice.currentDevice.ios7?
      frame = text.boundingRectWithSize(
        size,
        options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading,
        attributes:self.attributesWithFont(font, color:nil, lineBreakMode:lineBreakMode),
        context:nil
      )
      return CGSizeMake(frame.size.width.ceil, frame.size.height.ceil)
    else
      return text.sizeWithFont(font, constrainedToSize:size, lineBreakMode:lineBreakMode)
    end
  end

  def self.attributesWithFont(font, color:color, lineBreakMode:lineBreakMode)
    paragraph = NSMutableParagraphStyle.new
    paragraph.lineBreakMode = lineBreakMode
    return {
      NSFontAttributeName            => font,
      NSForegroundColorAttributeName => color,
      NSParagraphStyleAttributeName  => paragraph,
    }
  end
end
