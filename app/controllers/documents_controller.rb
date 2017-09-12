# frozen_string_literal: true

class DocumentsController < ApplicationController

  def index
    @documents = Document.all
  end

end
