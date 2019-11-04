module BlackStack
  
  # process class
  class MyCrawlProcess < BlackStack::MyLocalProcess
  
    attr_accessor :nErrors, :nSuccesses, :browser, :proxy, :bot
    
    # constructor
    def initialize(
      the_worker_name, 
      the_division_name, 
      the_minimum_enlapsed_seconds=MyProcess::DEFAULT_MINIMUM_ENLAPSED_SECONDS, 
      the_verify_configuration=true,
      the_email=nil, 
      the_password=nil
    )
      super(the_worker_name, the_division_name, the_minimum_enlapsed_seconds, the_verify_configuration, the_email, the_password)
      self.nErrors = 0
      self.nSuccesses = 0
      self.browser = nil
      self.proxy = nil
      self.bot = nil
    end
    
    def canRun?()
      super &&
      nErrors < Params.getValue("crawl.company.discretion.max_errors") && 
      nSuccesses < Params.getValue("crawl.company.discretion.max_successes")
      #(Params.getValue("crawl.company.use_proxy")==false || Company.availableProxiesWithDiscretionForCrawl() > 0)
    end
    
    def whyCantRun()
      ret = super
      if (ret.to_s.size == 0)
        if (self.nErrors >= Params.getValue("crawl.company.discretion.max_errors")) 
          return "Reached the max number of errors (#{self.nErrors.to_s})"
        end
  
        if (self.nSuccesses >= Params.getValue("crawl.company.discretion.max_successes"))      
          return "Reached the max number of successes (#{self.nSuccesses.to_s})"
        end
      end
      return ret
    end
    
  end # class MyCrawlProcess


end # module BlackStack