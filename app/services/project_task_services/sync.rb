module ProjectTaskServices
  class Sync
    DEFAULT_ADAPTER = ProjectTaskServices::SyncAdapters::Clickup

    def initialize(adapter: DEFAULT_ADAPTER)
      @adapter = adapter
    end

    def listTasks
    end

    def getTask(id)
    end

    def createTask(options)
    end

    def archiveTask(id)
    end

  end
end
