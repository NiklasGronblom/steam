module Locomotive::Steam
  module Models

    module Repository

      extend ActiveSupport::Concern
      extend Forwardable

      class RecordNotFound < StandardError; end

      attr_accessor :adapter, :scope, :local_conditions

      def_delegators :@scope, :site, :site=, :locale, :locale=

      def initialize(adapter, site = nil, locale = nil)
        @adapter  = adapter
        @scope    = Scope.new(site, locale)
        @local_conditions = {}
      end

      def build(attributes, &block)
        mapper.to_entity(attributes)
      end

      def create(entity)
        adapter.create(mapper, scope, entity)
      end

      def find(id)
        adapter.find(mapper, scope, id)
      end

      def query(&block)
        adapter.query(mapper, scope, &block)
      end

      def first(&block)
        adapter.query(mapper, scope, &block).first
      end

      def k(name, operator)
        adapter.key(name, operator)
      end

      alias :all :query

      def mapper(memoized = true)
        name, options, block = mapper_options

        return @mapper if @mapper && memoized

        @mapper = Mapper.new(name, options, self, &block)
      end

      def i18n_value_of(entity, name)
        mapper.i18n_value_of(entity, name, locale)
      end

      def prepare_conditions(*conditions)
        first = { order_by: @local_conditions.delete(:order_by) }.delete_if { |_, v| v.blank? }

        [first, *conditions].inject({}) do |memo, hash|
          memo.merge!(hash) unless hash.blank?
          memo
        end.merge(@local_conditions)
      end

      # TODO: not sure about that. could it be used further in the dev
      # def collection_name
      #   mapper.name
      # end

      module ClassMethods

        def mapping(name, options = {}, &block)
          class_eval do
            define_method(:mapper_options) { [name, options, block] }
          end
        end

      end

    end

  end
end
