# Apropos

Apropos helps your site serve up the appropriate image for every visitor. Serving multiple versions of an image in responsive and/or localized web sites can be a chore, but Apropos simplifies and automates this task. Instead of manually writing a lot of CSS rules to swap different images, Apropos generates CSS for you based on a simple file naming convention.

[![Build Status](https://travis-ci.org/square/apropos.png)](https://travis-ci.org/square/apropos)

## Installation

Apropos requires Ruby 1.9 or greater.

Add this line to your application's Gemfile:

    gem 'apropos'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apropos

## Usage

Apropos depends on [Compass](http://compass-style.org/), so make sure you have that installed and configured in your project.

## Why use Apropos?

There are many tools and techniques for using responsive images. What makes Apropos different? A few key principles:

- Let the browser do what it does best. CSS rules are more efficient and reliable than a solution that relies on Javascript or setting cookies for each visitor.
- Avoid duplicate downloads. Almost all Javascript solutions, including polyfills for things like `srcset`, require unnecessary extra downloads, which CSS classes and media queries avoid.
- No server logic should be required. Rather than setting a cookie and serving up different assets based on the cookie, we should be able to push compiled CSS and images to a CDN and rely on the browser to request the right images.
- Take advantage of the "metadata" encoded in file names. We need to create separate assets for high-dpi devices, breakpoints, locales, etc anyway. We can lean on the filesystem with a simple naming convention rather than hand-coding a bunch of CSS.

### Sample configuration

It's easy to get up and running with Apropos' basic configuration. Here's a sample stylesheet:

```sass
// Put this in a .sass (or .scss) file, such as application.css.sass

// Substitute with your own breakpoint names and sizes
$apropos-breakpoints: (medium, 768px), (large, 1024px)
@import "apropos"

.hero
  // Use hero.jpg as the background of this element, and load any image
  // variants that exist. If you use $generate-height: true, the function
  // will also generate height definitions based on the height of each
  // image (except dpi variants, since you want to display those at the
  // original dimensions).
  +apropos-bg-variants('hero.jpg', $generate-height: true)

  // Customize other background styles
  background-size: auto 100%
  background-position: 50%
```

With that configuration set up, you can include any set of variants on your image with a simple file naming convention:

    # File listing e.g. app/assets/images:
    hero.jpg
    hero.medium.jpg
    hero.large.jpg
    hero.2x.jpg
    hero.2x.medium.jpg
    hero.2x.large.jpg

In this example, `hero.jpg` would be your base image, most likely a mobile version. `hero.medium.jpg` would be swapped in at the 768px breakpoint, and `hero.large.jpg` would be swapped in at 1024px. On a high-dpi device, `hero.2x.jpg`, `hero.2x.medium.jpg`, and `hero.2x.large.jpg` would be used instead. Note that the order of the file extensions doesn't matter; `hero.2x.medium.jpg` and `hero.medium.2x.jpg` work exactly the same.

### Customization

You can customize Apropos' breakpoints as shown above, and you can also customize the definition of the "high dpi" variant:

```sass
// The default extension name is "2x", we're overriding to use "hidpi"
$apropos-hidpi-extension: "hidpi"
// The default ratio is 1.75 (or 168 dpi), but here we're overriding that
$apropos-hidpi-query: "(-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi)"
@import "apropos"
```

If you want to do more advanced configuration like adding variants for localization, you can [customize Apropos in Ruby](doc-src/customization.md).

### Hidpi Only mode

For some projects, it makes sense to only use high dpi images. If most of your visitors use high dpi devices, you can use fewer images and omit 1x assets. In fact, even for 1x devices you may be able to use higher compression rates on 2x assets that are scaled down. This also means your generated CSS only needs roughly half as many media queries. You can switch Apropos into "high dpi only" mode, where it will generate CSS definitions with halved heights and not output high dpi media queries, with the following config line:

```ruby
# Place this in a Ruby configuration file, e.g. Compass config or Rails initializer
Apropos.hidpi_only = true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Before any changes are merged to master, we need you to sign a very simple
[Individual Contributor Agreement](https://spreadsheets.google.com/a/squareup.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1)
(Google Form).

© 2013 Square, Inc.
