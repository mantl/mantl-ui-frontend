exports.config = {
    files: {
        javascripts: { joinTo: "lib.js" },
        stylesheets: { joinTo: "app.css" }
    },

    plugins: {
        postcss: {
            processors: [ require('autoprefixer')(['last 8 versions']) ]
        },
        elmBrunch: {
            elmFolder: '.',
            mainModules: [ 'app/Main.elm' ],
            outputFolder: 'public/'
        }
    }
};
