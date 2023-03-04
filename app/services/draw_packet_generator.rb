class DrawPacketGenerator
  require 'zip'

  class Error < StandardError; end

  READY_STATES = %i{internally_approved externally_approved}

  attr_reader :debug, :draw, :errors, :project

  def initialize(draw:, debug: false)
    @debug = debug
    @draw = draw
    raise Error.new('Invalid Draw argument') unless @draw.is_a?(Draw)

    @project = @draw.project
    reset_errors
  end
  
  def call
    reset_errors
    return false unless check_state

    @document_packet = generate_document_packet
  end

  def errors?
    errors.any?
  end

  private

  def reset_errors
    @errors = []
  end

  def check_state
    return true if READY_STATES.include?(@draw.state.to_sym)

    @errors << 'Draw not in a ready state' 

    false
  end

  def generate_document_packet
    draw_documents = get_draw_documents
    invoice_documents = get_invoice_documents
    zipfile_full_filename = nil
    zipfile_name = nil

    with_tempdir do |tmpdir|
      output_files = []
      all_docs = draw_documents + invoice_documents
      dest_subdir = "#{all_docs.first[:draw_name].parameterize.underscore}-#{Time.current.strftime("%Y%m%d%H%M")}"
      dest_dir = File.join(tmpdir, dest_subdir)
      zipfile_name = "#{dest_subdir}.zip"
      zipfile_full_filename = File.join(tmpdir, zipfile_name)

      Dir.mkdir(dest_dir)
      all_docs.each do |attachment_info|
        dest_file = File.join(dest_dir, attachment_info[:filename])
        output_files << attachment_info[:filename]
        attachment_info[:document].blob.open do |blob_tempfile|
          FileUtils.cp(blob_tempfile.path, dest_file)
        end
      end

      ::Zip::File.open(zipfile_full_filename, create: true) do |zipfile|
        output_files.each do |filename|
          zipfile.add(filename, File.join(dest_dir, filename))
        end
      end

      if debug
        debug_output = File.join(Rails.root, 'tmp', zipfile_name)
        FileUtils.cp(zipfile_full_filename, debug_output)
      end

      @draw.document_packet.attach(io: File.open(zipfile_full_filename), filename: zipfile_name)
    end

    @draw.document_packet
  end

  def get_draw_documents
    draw_name = @draw.name.parameterize.underscore
    doc_indices = { }
    @draw.draw_documents.approved.map do |draw_document|
      next nil unless draw_document.document&.attached?

      documenttype = draw_document.documenttype
      document_type = documenttype.capitalize
      index_key = documenttype.to_sym
      doc_indices[index_key] ||= 0
      doc_indices[index_key] = 1 + doc_indices[index_key]
      doc_index = "%03d" % doc_indices[index_key]
      {
        filename: "%{draw_name}-_%{document_type}Document%{doc_index}.pdf" %
                    { draw_name: , doc_index:, document_type: },
        draw_document_id: draw_document.id,
        document: draw_document.document,
        draw_name:
      }
    end.compact
  end

  def get_invoice_documents
    draw_name = @draw.name.parameterize.underscore
    index = 0 
    @draw.invoices.approved.map do |invoice|
      next nil unless invoice.document&.attached?
      index += 1
      doc_index = "%03d" % index
      draw_cost_name = invoice.draw_cost.name.underscore
      {
        filename: "%{draw_name}-%{draw_cost_name}%{doc_index}.pdf" %
                    { draw_name:, draw_cost_name:, doc_index:, },
        invoice_id: invoice.id,
        document: invoice.document,
        draw_name:
      }
    end.compact
  end

  def with_tempdir(&block)
    tmpdir = Dir.mktmpdir
    begin
      yield(tmpdir)
    ensure
      FileUtils.remove_entry tmpdir, true
    end

  end


end
