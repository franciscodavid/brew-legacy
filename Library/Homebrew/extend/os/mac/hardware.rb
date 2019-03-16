module Hardware
  def self.oldest_cpu(version = MacOS.version)
    if version >= :mojave
      :penryn
    else
      generic_oldest_cpu
    end
  end
end
