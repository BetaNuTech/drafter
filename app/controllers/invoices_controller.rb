class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw_cost
  before_action :set_invoice, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def new
    @invoice = @draw_cost.invoices.new
    authorize @invoice
  end

  def create
    authorize Invoice.new(draw_cost: @draw_cost)
    @service = InvoiceService.new(user: @current_user, draw_cost: @draw_cost)
    @invoice = @service.create(params[:invoice])
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      respond_to do |format|
        format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id), notice: 'Uploaded Invoice'}
        format.turbo_stream
      end
    end
  end

  def show
    authorize @invoice
  end

  def edit
    authorize @invoice
  end

  def update
    authorize @invoice
    @service = InvoiceService.new(user: @current_user, draw_cost: @draw_cost, invoice: @invoice)
    @service.update(params[:invoice])
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      respond_to do |format|
        format.html { redirect_to draw_cost_invoice_path(draw_cost_id: @draw_cost.id, id: @invoice.id)}
        format.turbo_stream
      end
    end
  end

  def destroy
    authorize @invoice
    @service = InvoiceService.new(user: @current_user, draw_cost: @draw_cost, invoice: @invoice)
    @service.remove
    respond_to do |format|
      format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id)}
      format.turbo_stream
    end
  end

  private

  def draw_cost_scope
    DrawCostPolicy::Scope.new(@current_user, DrawCost).resolve
  end

  def set_draw_cost
    @draw_cost = draw_cost_scope.find(params[:draw_cost_id])
  end

  def record_scope
    @draw_cost.invoices
  end

  def set_invoice
    @invoice = record_scope.find(params[:id])
  end
end
