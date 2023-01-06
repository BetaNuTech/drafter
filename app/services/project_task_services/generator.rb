module ProjectTaskServices
  class Generator
    class << self
      def call(origin:, assignee: nil, action:)
        class_name = origin.instance_of?(Class) ? origin.name : origin.class.name
        generator = "ProjectTaskServices::#{class_name}TaskGenerator".constantize
        generator.call(origin:, assignee:, action:)
      end

    end # Class methods
  end
end
