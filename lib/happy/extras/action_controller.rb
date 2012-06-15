module Happy
  module Extras

    # A Rails-like controller that dispatches to individual actions
    # named in the URL.
    #
    # The controller's root URL will call the `index` method, any sub-path
    # will call the method by that name. If a third path is provided, it
    # will be assigned to params['id'].
    #
    # /         # index
    # /foo      # foo
    # /foo/123  # foo (with params['id'] set to 123)
    #
    class ActionController < Happy::Controller
      def dispatch_to_method(name)
        send(name) if public_methods.include?(name.to_sym)
      end

      def route
        on :action do
          on :id do
            dispatch_to_method params['action']
          end

          dispatch_to_method params['action']
        end

        index
      end
    end

  end
end