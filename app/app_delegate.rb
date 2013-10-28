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
    #@state = UILabel.new
    #@state.font = UIFont.systemFontOfSize(30)
    #@state.text = 'Tap to start'
    ##@state.textAlignment = UITextAlignmentCenter
    #@state.textColor = UIColor.whiteColor
    #@state.backgroundColor = UIColor.clearColor
    #@state.frame = [[margin, 200], [view.frame.size.width - margin * 2, 40]]
    #self.view.addSubview(@state)

    #@photo.photoRect
    #view.addSubview(@state)
    #@clock = Clock.new
    #view.addSubview(@clock)
    tokei = RTTokei.new
    view.addSubview tokei
  end

end

class RTTokei < UILabel
  CLOCK_FORMAT = "%H %M"

  def init
    s = super

    font = UIFont.fontWithName("AvenirNext-Bold", size: 72)
    text_size = RTTextUtil.text(timeString, sizeWithFont: font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    self.font = font
    self.textAlignment = NSTextAlignmentLeft
    self.textColor = UIColor.whiteColor.colorWithAlphaComponent(0.9)
    self.backgroundColor = UIColor.clearColor
    self.text = timeString
    self.frame = [[60, 20], text_size]
    startTimer
    s
  end

  attr_reader :timer
  def startTimer
    if @timer
      @timer.invalidate
      @timer = nil
    else
      @timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target:self, selector:'timerFired', userInfo:nil, repeats:true)
    end
  end

  def timeString
    Time.now.strftime(CLOCK_FORMAT)
  end

  def timeSeparator
    if @sep_cycle
      @sep_cycle = false
      " "
    else
      @sep_cycle = true
      ":"
    end
  end

  def timerFired
    self.text = timeString
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

    padding = 5

    name = 'Koichi SASADA'
    name_font = UIFont.fontWithName("AvenirNext-Bold", size: 30)
    name_text_size = RTTextUtil.text(name, sizeWithFont: name_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @name.font = name_font
    @name.textColor = UIColor.whiteColor
    @name.backgroundColor = UIColor.clearColor
    @name.text = name
    @name.frame = [[padding, 0], name_text_size]
    addSubview(@name)

    title = '@koichisasada as a teacher'
    title_font_size = 16
    begin
      title_font = UIFont.fontWithName("AvenirNext-Medium", size: title_font_size)
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

    second_line_height = name_text_size.height - padding

    bio = "YARV Creator"
    bio_font = UIFont.fontWithName("AvenirNext-Medium", size: 16)
    bio_text_size = RTTextUtil.text(bio, sizeWithFont: bio_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
    @bio.font = bio_font
    @bio.textColor = UIColor.whiteColor
    @bio.backgroundColor = UIColor.clearColor
    @bio.text = bio
    @bio.frame = [[padding, second_line_height], bio_text_size]
    addSubview(@bio)

    taken_by = "- Photo taken by Marcin Bajer"
    taken_by_font_size = 14
    begin
      taken_by_font = UIFont.fontWithName("AvenirNext-MediumItalic", size: taken_by_font_size)
      taken_by_font_size -= 1
      taken_by_text_size = RTTextUtil.text(taken_by, sizeWithFont: taken_by_font, constrainedToSize: [1000, 1000], lineBreakMode: NSLineBreakByTruncatingHead)
      # XXX: bio のサイズが frame より大きかった場合バグる
    end while bio_text_size.width + padding * 3 + taken_by_text_size.width > frame.size.width
    @taken_by.font = taken_by_font
    @taken_by.textColor = UIColor.whiteColor
    @taken_by.backgroundColor = UIColor.clearColor
    @taken_by.text = taken_by
    @taken_by.frame = [[bio_text_size.width + padding * 2, second_line_height + bio_text_size.height - taken_by_text_size.height],
                    taken_by_text_size]
    addSubview(@taken_by)
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
