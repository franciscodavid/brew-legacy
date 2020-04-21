# frozen_string_literal: true

require "cli/parser"

module Homebrew
  module_function

  def mirror_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `mirror` <formula>

        Reupload the stable URL of a formula to Bintray for use as a mirror.
      EOS
      switch :verbose
      switch :debug
      hide_from_man_page!
      min_named :formula
    end
  end

  def mirror
    mirror_args.parse

    bintray_user = Homebrew::EnvConfig.bintray_user
    bintray_key = Homebrew::EnvConfig.bintray_key
    raise "Missing HOMEBREW_BINTRAY_USER or HOMEBREW_BINTRAY_KEY variables!" if !bintray_user || !bintray_key

    args.formulae.each do |f|
      bintray_package = Utils::Bottles::Bintray.package f.name
      bintray_repo_url = "https://api.bintray.com/packages/homebrew/mirror"
      package_url = "#{bintray_repo_url}/#{bintray_package}"

      unless system curl_executable, "--silent", "--fail", "--output", "/dev/null", package_url
        package_blob = <<~JSON
          {"name": "#{bintray_package}",
           "public_download_numbers": true,
           "public_stats": true}
        JSON
        curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
             "--header", "Content-Type: application/json",
             "--data", package_blob, bintray_repo_url
        puts
      end

      downloader = f.downloader

      downloader.fetch

      filename = downloader.basename

      destination_url = "https://dl.bintray.com/homebrew/mirror/#{filename}"
      ohai "Uploading to #{destination_url}"

      content_url =
        "https://api.bintray.com/content/homebrew/mirror/#{bintray_package}/#{f.pkg_version}/#{filename}?publish=1"
      curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
           "--upload-file", downloader.cached_location, content_url
      puts
      ohai "Mirrored #{filename}!"
    end
  end
end
