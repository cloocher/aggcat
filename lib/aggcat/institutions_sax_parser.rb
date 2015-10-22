module Aggcat
  class InstitutionsSaxParser < ::Ox::Sax
    def initialize(block)
      @block = block
      @item = {}
    end
    ITEM_ELEMENT = :institution
    def start_element(name)
      @current_element = name
      @item = {} if name == ITEM_ELEMENT
    end

    def end_element(name)
      @block.call(@item) if name == ITEM_ELEMENT
    end

    def text(value) 
      @item[@current_element] = value
    end
  end
end
