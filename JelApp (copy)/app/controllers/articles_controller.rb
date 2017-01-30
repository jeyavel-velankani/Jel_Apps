class ArticlesController < ApplicationController
  require 'tempfile'

  def index
    @articles = Article.all
  end

  def new
  	@article = Article.new 

  end

  def edit
    @article = Article.find(params[:id])
  end

  def show
    @article = Article.find(params[:id])

    file = Tempfile.new('foo')
    file.path      # => A unique filename in the OS's temp directory,
                   #    e.g.: "/tmp/foo.24722.0"
                   #    This filename contains 'foo' in its basename.
    file.write("hello world")
    # file.rewind
    # file.read      # => "hello world"
    
    send_data(file.path)

    file.close
    file.unlink    # deletes the temp file
  end

  def create
  @article = Article.new(article_params)
 
  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end
 
def update
  @article = Article.find(params[:id])
 
  if @article.update(article_params)
    redirect_to @article
  else
    render 'edit'
  end
end

def destroy
    @article = Article.find(params[:id])
    @article.destroy
 
    redirect_to articles_path
  end
 
private
  def article_params
    params.require(:article).permit(:title, :text)
  end
end