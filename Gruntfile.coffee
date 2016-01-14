'use strict'

mountFolder = folderMount = (connect, base) ->
  connect['static'] require('path').resolve(base)

listen = 8000
server = 3000

module.exports = (grunt) ->
  require('load-grunt-tasks')(grunt)
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    # Metadata.
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' + '<%= grunt.template.today(\'yyyy-mm-dd\') %>\n' + '<%= pkg.homepage ? \'* \' + pkg.homepage + \'\\n\' : \'\' %>' + '* Copyright (c) <%= grunt.template.today(\'yyyy\') %> <%= pkg.author.name %>;' + ' Licensed <%= _.pluck(pkg.licenses, \'type\').join(\', \') %> */\n'

    dir:
      src: 'app'
      styl: 'stylesheets'
      coffee: 'javascripts'
      images: 'images'
      js: 'javascripts'
      css: 'stylesheets'
      img: 'images'
      vendors: 'vendors'
      dist: 'dist'
      build: 'build'
      docs: 'docs'
      test: 'test'

    bower:
      install:
        options:
          targetDir: './dist/public/bower_components'
          layout: 'byComponent'
          install: true
          verbose: true
          cleanTargetDir: true
          cleanBowerDir: true

    stylus:
      dist:
        options:
          compress: false
        expand: true
        cwd: '<%= dir.src %>'
        src: '**/*.styl'
        dest: '<%= dir.dist %>'
        ext: '.css'

    coffee:
      dist:
        option:
          pretty: true
        expand: true
        cwd: '<%= dir.src %>'
        src: '**/*.coffee'
        dest: '<%= dir.dist %>'
        ext: '.js'

    # coffeeの文法チェック
    coffeelint:
      app: '<%= dir.src %>/**/*.coffee'

    # CSSのprefiexを補完
    autoprefixer:
      options:
        browsers: ['last 2 version', 'ie 8', 'ie 7', 'ie 6']
      dist:
        expand: true
        cwd: '<%= dir.dist %>'
        src: '**/*.css'
        dest: '<%= dir.dist %>'
        ext: '.css'

    # 画像の圧縮
    imagemin:
      options:
        optimizationLevel: 7
        pngquant: false
      dist:
        expand: true
        cwd: '<%= dir.dist %>/<%= dir.images %>'
        src: '**/*.{jpg,jpeg,gif}'
        dest: '<%= dir.dist %>/<%= dir.img %>'

    copy:
      jade:
        expand: true
        dot: true
        cwd: '<%= dir.src %>'
        dest: '<%= dir.dist %>'
        src: '**/*.jade'
      bin:
        expand: true
        cwd: '<%= dir.src %>/bin'
        dest: '<%= dir.dist %>/bin'
        src: '**'
      img:
        expand: true
        dot: true
        cwd: '<%= dir.src %>'
        dest: '<%= dir.dist %>'
        src: [
          '**/*.{gif,jpeg,jpg,png,svg,webp}',
        ]
      vendors:
        expand: true
        dot: true
        cwd: '<%= dir.src %>/public/vendors'
        dest: '<%= dir.dist %>/public/vendors'
        src: '**'

      test:
        expand: true
        dot: true
        cwd: '<%= dir.src %>/test'
        dest: '<%= dir.dist %>/test'
        src: '**'


    connect:
      front:
        options:
          host: 'localhost'
          port: listen
          middleware: (connect) ->
            [
              mountFolder(connect, '.')
              proxySnippet = require('grunt-connect-proxy/lib/utils').proxyRequest
            ]

          open:
            target: 'http://localhost:' + listen

          livereload: true

      proxies: [
        context: '/'
        host: 'localhost'
        port: server + ''
        https: false
        changeOrigin: false
      ]

    express:
      dev:
        options:
          background: true
          port: server
          cmd: 'supervisor'
          args: []
          script: '<%= dir.dist %>/bin/www'
          delay: 0

    watch:
      options:
        livereload: true
      jade:
        files: '<%= dir.src %>/**/*.jade',
        tasks: 'newer:copy:jade'
      stylus:
        files: '<%= dir.src %>/**/*.styl'
        tasks: [
          'newer:stylus:dist',
          'newer:autoprefixer:dist',
        ]
      coffee:
        files: '<%= dir.src %>/**/*.coffee'
        tasks: 'newer:coffee:dist'
      images:
        files: ['<%= dir.src %>/**/*.{gif,jpeg,jpg,png,svg,webp}']
        tasks: ['newer:imagemin:dist', 'copy', 'imagemin']
      vendors:
        files: ['<%= dir.src %>/public/vendors']
        tasks: ['copy:vendors']
      test:
        files: ['<%= dir.src %>/test']
        tasks: ['copy:test']
      express:
        files: [
          '<%= dir.dist %>/app.js'
          '<%= dir.dist %>/routes/**/*.js'
          '<%= dir.dist %>/views/**/*.jade'
        ]
        tasks: ['express:dev']
        options:
          livereload: true

      veiw:
        files: ['<%= dir.dist %>/public/**/*.{js,css}']

    simplemocha:
      all:
        src: ['<%= dir.dist %>/test/**/*.js']
      options:
        reporter: 'nyan'
        ui: 'bdd'

    clean:
      dist:
        src: [
          '<%= dir.dist %>'
        ]

  grunt.registerTask 'server', [
    'configureProxies'
    'express:dev'
    'connect:front'
    'watch'
  ]

  grunt.registerTask 'default', [
    'clean'
    'bower:install'
    'stylus:dist'
    'autoprefixer'
    'coffee:dist'
    'copy:jade'
    'copy:img'
    'copy:bin'
    'copy:vendors'
    'imagemin'
    'simplemocha'
  ]

  grunt.registerTask 'dev', [
    'default'
    'configureProxies'
    'express:dev'
    'connect:front'
    'watch'
  ]

  grunt.registerTask 'build', [
    'default'
  ]

  grunt.registerTask 'test', [
    'simplemocha'
  ]
