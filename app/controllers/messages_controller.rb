class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  before_action :set_messageable, only: [:index, :show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /messages
  # GET /messages.json
  def index
    authorize Message
    @messages = record_scope
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(message_params)

    respond_to do |format|
      if @message.save
        format.html { redirect_to @message, notice: 'Message was successfully created.' }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to @message, notice: 'Message was successfully updated.' }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def record_scope
      return @messageable.present? ?
        policy_scope(@messageable.messages) :
        policy_scope(Message)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = record_scope.find(params[:id])
    end

    def set_messageable
      @messageable = nil
      if (lead_id = params[:lead_id]).present?
        @messageable = Lead.find(lead_id)
      end
      return @messageable
    end

    def message_params
      params.require(:message).permit(policy(Message).allowed_params)
    end
end
