module Onsi
  module Graph
    ##
    # @private
    class AutoLoader
      class << self
        ##
        # @private
        def auto_load(path, target_module)
          (target_module.name.split('::') + class_base_parts(path, target_module)).join('::').constantize
        end

        private

        def class_base_parts(path, target_module)
          path.gsub(target_module.path.to_s, '')
            .split(File::SEPARATOR).reject(&:empty?)
            .map { |part| part.split('.').first.camelize }
        end
      end
    end
  end
end
