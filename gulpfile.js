var gulp = require('gulp'),
    jisp = require('gulp-jisp'),
    plumber = require('gulp-plumber'),
    fs = require('fs');
 
var s3 = require('gulp-s3-upload')(JSON.parse(fs.readFileSync('./aws.json')));
var s3options = {Bucket : "flowblock", ACL : "public-read"};

gulp.task('scripts', function(){
    gulp.src('*.jisp').pipe(plumber()).pipe(jisp()).pipe(gulp.dest('./build')).pipe(s3(s3options));
});
gulp.task('html', function(){
    gulp.src('./index.html').pipe(gulp.dest('./build')).pipe(s3(s3options));
});

gulp.task('watch', function() {
  gulp.watch("*.jisp", ['scripts']);
  gulp.watch("./index.html", ['html']);
});

gulp.task('default', ["watch", "scripts", "html"]);
