class DrawsController < ApplicationController
  before_action :set_draw, only: %i[ show edit update destroy ]

  # GET /draws or /draws.json
  def index
    @draws = Draw.all
  end

  # GET /draws/1 or /draws/1.json
  def show
  end

  # GET /draws/new
  def new
    @draw = Draw.new
  end

  # GET /draws/1/edit
  def edit
  end

  # POST /draws or /draws.json
  def create
    @draw = Draw.new(draw_params)

    respond_to do |format|
      if @draw.save
        format.html { redirect_to draw_url(@draw), notice: "Draw was successfully created." }
        format.json { render :show, status: :created, location: @draw }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @draw.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /draws/1 or /draws/1.json
  def update
    respond_to do |format|
      if @draw.update(draw_params)
        format.html { redirect_to draw_url(@draw), notice: "Draw was successfully updated." }
        format.json { render :show, status: :ok, location: @draw }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @draw.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /draws/1 or /draws/1.json
  def destroy
    @draw.destroy

    respond_to do |format|
      format.html { redirect_to draws_url, notice: "Draw was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_draw
      @draw = Draw.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def draw_params
      params.require(:draw).permit(:project_id, :index, :name, :state, :reference, :total, :approver, :notes)
    end
end
