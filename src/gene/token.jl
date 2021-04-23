mutable struct Token  # Item
    target::HashValue
    bgt::Budget
end

priority(tk::Token) = tk.bgt.priority
durability(tk::Token) = tk.bgt.durability
quality(tk::Token) = tk.bgt.quality

Base.:(==)(tk::Token, other::Token) = tk.target == other.target
Base.merge!(tk1::Token, tk2::Token) = merge!(tk1.bgt, tk2.bgt)
