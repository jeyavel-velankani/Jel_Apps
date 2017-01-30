class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts
  # GET /posts.json
  def index
    # Normal query to get the post details
    # @posts = Post.order(created_at: :desc)    
    # Post Load (0.6ms)  SELECT "posts".* FROM "posts"  ORDER BY "posts"."created_at" DESC
    # Author Load (0.5ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = ? LIMIT 1  [["id", 3]]
    # Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = ? LIMIT 1  [["id", 2]]
    # Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = ? LIMIT 1  [["id", 1]]
    
    # Preload
    # @posts = Post.order(created_at: :desc).preload(:author)
    # SELECT "posts".* FROM "posts"  ORDER BY "posts"."created_at" DESC
    # SELECT "authors".* FROM "authors" WHERE "authors"."id" IN (3, 2, 1)


    #egaer Load
    # @posts = Post.order(created_at: :desc).eager_load(:author)
    # SELECT "posts"."id" AS t0_r0, "posts"."title" AS t0_r1, "posts"."body" AS t0_r2, "posts"."author_id" AS t0_r3, "posts"."created_at" AS t0_r4, "posts"."updated_at" AS t0_r5, "authors"."id" AS t1_r0, "authors"."name" AS t1_r1, "authors"."created_at" AS t1_r2, "authors"."updated_at" AS t1_r3 
    # FROM "posts"
    # LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"
    # ORDER BY authors.name

    #includes
    @posts = Post.order(created_at: :desc).includes(:author)
    # if we compare the results with the eager_load() method, the first two cases have similar results, but in the last case it smartly decided to shift to the preload() method for better performance

  end

  # GET /posts/1
  # GET /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:title, :body, :author_id)
    end
end
