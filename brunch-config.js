exports.config = {
    files: {
        javascripts: { joinTo: "scripts/lib.js" },
        stylesheets: { joinTo: "styles/app.css" }
    },

    plugins: {
        postcss: {
            processors: [ require('autoprefixer')(['last 8 versions']) ]
        },
        elmBrunch: {
            elmFolder: '.',
            mainModules: [ 'app/Main.elm' ],
            outputFolder: 'public/scripts/'
        },
        gzip: {
            paths: {
                javascript: 'scripts/',
                stylesheet: 'styles/'
            }
        },
        appcache: {
            ignore: /signature/
        }
    }
};
