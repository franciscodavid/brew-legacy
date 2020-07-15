# frozen_string_literal: true

module Hardware
  def self.oldest_cpu(version = MacOS.version)
    if CPU.arch == :arm64
      :arm_vortex_tempest
    elsif version >= :mojave
      :core2
    else
      generic_oldest_cpu
    end
  end
end
