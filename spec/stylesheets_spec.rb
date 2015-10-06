require 'spec_helper'
require 'fileutils'
require 'tmpdir'

describe 'stylesheets' do
  let(:import_options) { {style: :compact, load_paths: [Apropos::STYLESHEETS_DIR], syntax: :scss} }
  let(:css_file) { Sass::Engine.new(@scss_file, import_options).render }
  let(:images_dir) {
    Dir.mktmpdir('apropos').tap do |dir|
      at_exit { FileUtils.remove_entry_secure(dir) }
    end
  }

  before do
    Compass.configuration.stub(:http_images_path) { '/' }
    Compass.configuration.stub(:images_path) { images_dir }
    Compass.configuration.stub(:asset_cache_buster).and_return( lambda { |path| nil } )
  end

  after { Apropos.clear_image_variants }

  def stub_files(files)
    FileUtils.cd(images_dir) do
      FileUtils.touch(files)
    end
  end

  it "can be imported" do
    stub_files(%w[hero.jpg])
    @scss_file = %Q{
      @import "apropos";
      .foo {
        @include apropos-bg-variants('hero.jpg');
      }
    }
    css_file.strip.should == ".foo { background-image: url('/hero.jpg'); }"
  end

  context "with fixture images" do
    before do
      Compass.configuration.stub(:images_path) { File.expand_path('fixtures/images', File.dirname(__FILE__)) }
    end

    it "can generate heights" do
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('kitten.jpg', true);
        }
      }
      css_file.strip.should == ".foo { background-image: url('/kitten.jpg'); height: 286px; }"
    end

    it "class variants can generate heights" do
      Apropos.add_class_image_variant('variant', %w(variant))
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('kitten.jpg', true);
        }
      }
      css_file.strip.should include(".variant .foo { background-image: url('/kitten.variant.jpg'); height: 386px; }")
    end
  end

  describe "hidpi stylesheet" do
    it "generates default hidpi rules" do
      stub_files(%w[hero.jpg hero.2x.jpg])
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include('(-webkit-min-device-pixel-ratio: 1.75), (min-resolution: 168dpi)')
      css_file.should include("'/hero.2x.jpg'")
    end

    it "allows customizing hidpi extension and query" do
      stub_files(%w[hero.jpg hero.hidpi.jpg])
      @scss_file = %Q{
        $apropos-hidpi-extension: 'hidpi';
        $apropos-hidpi-query: '(min-resolution: 300dpi)';
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should_not include('(-webkit-min-device-pixel-ratio: 1.75)')
      css_file.should include('(min-resolution: 300dpi)')
      css_file.should include("'/hero.hidpi.jpg'")
    end
  end

  describe "breakpoints stylesheet" do
    before :each do
      stub_files(%w[hero.jpg hero.medium.jpg hero.large.jpg])
    end

    it "doesn't generate any defaults" do
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should_not include('/hero.medium.jpg')
      css_file.should_not include('/hero.large.jpg')
    end

    it "allows setting breakpoints" do
      stub_files(%w[hero.jpg hero.extra-small.jpg hero.small.jpg hero.medium.jpg hero.large.jpg hero.extra-large.jpg])
      @scss_file = %Q{
        $apropos-breakpoints: ("extra-small", 374px), ("small", 480px), ("medium", 768px), ("large", 1024px), ("extra-large", 1292px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include(".foo { background-image: url('/hero.jpg'); }")
      css_file.should include("@media (min-width: 374px) { .foo { background-image: url('/hero.extra-small.jpg'); } }")
      css_file.should include("@media (min-width: 480px) { .foo { background-image: url('/hero.small.jpg'); } }")
      css_file.should include("@media (min-width: 768px) { .foo { background-image: url('/hero.medium.jpg'); } }")
      css_file.should include("@media (min-width: 1024px) { .foo { background-image: url('/hero.large.jpg'); } }")
      css_file.should include("@media (min-width: 1292px) { .foo { background-image: url('/hero.extra-large.jpg'); } }")
    end
  end

  describe "breakpoints and hidpi" do
    it "can be combined" do
      stub_files(%w[hero.jpg hero.large.2x.jpg hero.medium.2x.jpg])
      @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should include("@media (min-width: 768px) and (-webkit-min-device-pixel-ratio: 1.75), (min-width: 768px) and (min-resolution: 168dpi) { .foo { background-image: url('/hero.medium.2x.jpg'); } }")
      css_file.should include("@media (min-width: 1024px) and (-webkit-min-device-pixel-ratio: 1.75), (min-width: 1024px) and (min-resolution: 168dpi) { .foo { background-image: url('/hero.large.2x.jpg'); } }")
    end

    it "sorts breakpoints vs. retina correctly" do
      # filesystem sort order
      files = %w[2x large.2x large medium.2x medium].map {|f| "hero.#{f}.jpg" } + %w[hero.jpg]
      stub_files(files)
      @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      images = css_file.scan(/hero.+jpg/)
      sorted_images = %w[2x medium medium.2x large large.2x].map {|f| "hero.#{f}.jpg" }
      images.should == ["hero.jpg"] + sorted_images
    end
  end

  describe "invalid variants" do
    let(:log) { '' }

    before :each do
      stub_files(%w[hero.jpg hero.foo.jpg hero.bar.jpg])
      Sass.logger.stub(:info) do |message|
        log << message << "\n"
      end
    end

    it "logs invalid variants during compilation" do
      @scss_file = %Q{
        @import "apropos";
        .foo {
          @include apropos-bg-variants('hero.jpg');
        }
      }
      css_file.should_not include('/hero.foo.jpg')
      css_file.should_not include('/hero.bar.jpg')
      log.should include("unknown extensions 'foo'")
      log.should include("unknown extensions 'bar'")
    end
  end

  context "hidpi-only mode" do
    let(:images_path) { File.expand_path('fixtures/images', File.dirname(__FILE__)) }

    before do
      Apropos.hidpi_only = true
      Compass.configuration.stub(:images_path) { images_path }
    end

    after do
      Apropos.hidpi_only = false
    end

    it "generates halved heights" do
      @scss_file = %Q{
        @import "apropos/core";
        .foo {
          @include apropos-bg-variants('kitten.jpg', true);
        }
      }
      css_file.strip.should == ".foo { background-image: url('/kitten.jpg'); height: 143px; }"
    end

    context "with dpi variant images" do
      let(:log) { '' }
      let(:images_path) { images_dir }

      before do
        Sass.logger.stub(:warn) do |message|
          log << message << "\n"
        end
      end

      it "outputs a warning" do
        stub_files(%w[hero.jpg hero.2x.jpg])
        @scss_file = %Q{
          @import "apropos";
          .foo {
            @include apropos-bg-variants('hero.jpg');
          }
        }
        css_file
        log.should include("DPI variant images detected in hidpi-only mode!")
      end
    end

    context "with breakpoints" do
      it "generates media queries and halved heights" do
        @scss_file = %Q{
        $apropos-breakpoints: (medium, 768px), (large, 1024px);
        @import "apropos/core";
        @import "apropos/breakpoints";
        .foo {
          @include apropos-bg-variants('cat.jpg', true);
        }
        }
        css_file.should include(".foo { background-image: url('/cat.jpg'); height: 150px; }")
        css_file.should include("@media (min-width: 768px) { .foo { background-image: url('/cat.medium.jpg'); height: 225px; } }")
        css_file.should include("@media (min-width: 1024px) { .foo { background-image: url('/cat.large.jpg'); height: 300px; } }")
      end
    end
  end
end
