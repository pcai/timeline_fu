module TimelineFu
  module Fires
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods

        attr_accessor :last_timeline_events

        after_initialize -> { self.last_timeline_events ||= TimelineEventsArray.new }
      end
    end

    module ClassMethods
      def fires(event_type, opts)
        raise ArgumentError, 'Argument :on is mandatory' unless opts.has_key?(:on)

        # Array provided, set multiple callbacks
        if opts[:on].kind_of?(Array)
          opts[:on].each { |on| fires(event_type, opts.merge(on: on)) }
          return
        end

        on = opts.delete(:on)
        _if = opts.delete(:if)
        _unless = opts.delete(:unless)

        method_name = :"fire_#{event_type}_after_#{on}"
        define_hook(event_type, method_name, opts)

        send(:"after_#{on}", method_name, if: _if, unless: _unless)
      end

      private

      def define_hook(event_type, method_name, opts)
        define_method(method_name) do
          create_options = opts_to_create_options(opts)
          callback = create_options.delete(:callback)
          create_options[:event_type] = event_type.to_s
          create_options[:subject] = self unless create_options.has_key?(:subject)

          event_class_names = Array(create_options.delete(:event_class_name) || 'TimelineEvent')
          event_class_names.each do |class_name|
            fire_event(class_name, callback, create_options)
          end
        end
      end


    end

    class TimelineEventsArray
      def initialize
        @timeline_events = []
      end

      def <<(timeline_event)
        @timeline_events << timeline_event
      end

      def of_type(type)
        @timeline_events.select{ |timeline_event| timeline_event.event_type == type }
      end

      def last_of_type(type)
        of_type(type).last
      end

      def include?(obj)
        @timeline_events.include?(obj)
      end
    end

    private

    def fire_event(class_name, callback, create_options)
      event = class_name.classify.constantize.create!(create_options)
      self.last_timeline_events << event

      if callback && self.respond_to?(callback)
        if [1,-1].include?(method(callback).arity)
          self.send(callback, event)
        elsif method(callback).arity == 0
          self.send(callback)
        end
      end
    end

    def opts_to_create_options(opts)
      opts.keys.inject({}) do |memo, sym|
        if opts[sym]
          if opts[sym].respond_to?(:call)
            memo[sym] = opts[sym].call(self)
          elsif opts[sym] == :self
            memo[sym] = self
          elsif sym == :callback || sym == :event_class_name
            memo[sym] = opts[sym]
          else
            memo[sym] = send(opts[sym])
          end
        end
        memo
      end
    end

  end
end
