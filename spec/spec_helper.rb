$spec_dir = File.dirname(__FILE__)
require File.join(File.expand_path($spec_dir), '../lib/lyp')
require 'fileutils'
require 'open3'

$packages_dir = Lyp.packages_dir
$lilyponds_dir = Lyp.lilyponds_dir

module Lyp
  def self.packages_dir
    $packages_dir
  end

  def self.lilyponds_dir
    $lilyponds_dir
  end

  def self.ext_dir
    ensure_dir("#{Lyp::TMP_ROOT}/ext")
  end

  def self.settings_file
    "#{Lyp::TMP_ROOT}/#{Lyp::SETTINGS_FILENAME}"
  end

  module Lilypond
    def self.get_system_lilyponds_paths
      []
    end

    def self.session_settings_filename
      "#{Lyp::TMP_ROOT}/session.#{Process.pid}.yml"
    end

    def self.invoke(argv, opts = {})
      lilypond = current_lilypond

      case opts[:mode]
      when :system
        run_cmd("#{lilypond} #{argv.join(' ')}", false)
      else
        run_cmd("#{lilypond} #{argv.join(' ')}")
        true
      end
    end

    def download_lilypond(url, fn, opts)
      STDERR.puts "Downloading #{url}" unless opts[:silent]

      if opts[:silent]
        `curl -s -o "#{fn}" "#{url}"`
      else
        `curl -o "#{fn}" "#{url}"`
      end
    end
  end
end

def with_packages(setup, opts = {})
  begin
    if setup == :tmp
      FileUtils.rm_rf("#{$spec_dir}/package_setups/tmp")

      if opts[:copy_from]
        FileUtils.cp_r("#{$spec_dir}/package_setups/#{opts[:copy_from]}",
          "#{$spec_dir}/package_setups/tmp")
      else
        FileUtils.mkdir("#{$spec_dir}/package_setups/tmp")
      end
    end

    old_packages_dir = $packages_dir
    $packages_dir = File.expand_path("package_setups/#{setup}", $spec_dir)

    # remove settings file
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)

    yield
  ensure
    # remove settings file
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)
    FileUtils.rm_rf(Lyp.ext_dir)

    $packages_dir = old_packages_dir
  end
end

def with_lilyponds(setup, opts = {})
  begin
    if setup == :tmp
      FileUtils.rm_rf("#{$spec_dir}/lilypond_setups/tmp")

      if opts[:copy_from]
        FileUtils.cp_r("#{$spec_dir}/lilypond_setups/#{opts[:copy_from]}",
          "#{$spec_dir}/lilypond_setups/tmp")
      else
        FileUtils.mkdir("#{$spec_dir}/lilypond_setups/tmp")
      end
    end

    old_lilyponds_dir = $lilyponds_dir
    $lilyponds_dir = File.expand_path("lilypond_setups/#{setup}", $spec_dir)

    # remove settings file
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)

    original_files = Dir["#{$lilyponds_dir}/*"]

    yield
  ensure
    # remove settings file
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)

    # remove any created files

    Dir["#{$lilyponds_dir}/*"].each do |fn|
      FileUtils.rm_rf(fn) unless original_files.include?(fn)
    end

    $lilyponds_dir = old_lilyponds_dir
  end
end

class String
  def strip_whitespace
    gsub(/\n/, ' ').gsub(/[ ]{2,}/, ' ').strip
  end
end

# Install hooks to create and delete tmp directory
RSpec.configure do |config|
  config.before(:all) do
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)
  end

  config.after(:all) do
    FileUtils.rm_rf("#{$spec_dir}/lilypond_setups/tmp")
    FileUtils.rm_rf("#{$spec_dir}/package_setups/tmp")
  end

  config.before(:each) do
    FileUtils.rm_f(Lyp.settings_file)
    FileUtils.rm_f(Lyp::Lilypond.session_settings_filename)
  end
end
