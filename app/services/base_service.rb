# frozen_string_literal: true

class BaseService
  def perform
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
