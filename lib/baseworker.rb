module BlackStack
  module BaseWorker
    KEEP_ACTIVE_MINUTES = 5 # if the worker didnt send a ping during the last X minutes, it is considered as not-active
  end # BaseWorker
end # module BlackStack