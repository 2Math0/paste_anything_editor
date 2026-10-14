/// A single math symbol: the Unicode character pasted as text, and its LaTeX
/// command used inside formulas.
class PaeMathSymbol {
  const PaeMathSymbol(this.char, this.name, [this.latex]);

  final String char;
  final String name;
  final String? latex;

  String get latexOrChar => latex ?? char;
}

class PaeMathSymbolGroup {
  const PaeMathSymbolGroup(this.title, this.symbols);

  final String title;
  final List<PaeMathSymbol> symbols;
}

/// A LaTeX snippet inserted from the formula panel.
class PaeMathTemplate {
  const PaeMathTemplate(this.label, this.latex, this.tooltip);

  final String label;
  final String latex;
  final String tooltip;
}

const List<PaeMathTemplate> kPaeMathTemplates = [
  PaeMathTemplate('a⁄b', r'\frac{a}{b}', 'Fraction'),
  PaeMathTemplate('√x', r'\sqrt{x}', 'Square root'),
  PaeMathTemplate('ⁿ√x', r'\sqrt[n]{x}', 'n-th root'),
  PaeMathTemplate('xⁿ', r'x^{n}', 'Power'),
  PaeMathTemplate('xₙ', r'x_{n}', 'Subscript'),
  PaeMathTemplate('∑', r'\sum_{i=1}^{n} ', 'Sum'),
  PaeMathTemplate('∏', r'\prod_{i=1}^{n} ', 'Product'),
  PaeMathTemplate('∫', r'\int_{a}^{b} f(x)\,dx', 'Integral'),
  PaeMathTemplate('lim', r'\lim_{x \to \infty} ', 'Limit'),
  PaeMathTemplate('d/dx', r'\frac{d}{dx}', 'Derivative'),
  PaeMathTemplate('log', r'\log_{b}(x)', 'Logarithm'),
  PaeMathTemplate('( )', r'\left( x \right)', 'Parentheses'),
  PaeMathTemplate('|x|', r'\left| x \right|', 'Absolute value'),
  PaeMathTemplate('x̄', r'\overline{x}', 'Overline'),
  PaeMathTemplate('v⃗', r'\vec{v}', 'Vector'),
  PaeMathTemplate('[ ]', r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
      'Matrix'),
  PaeMathTemplate('{ }', r'f(x) = \begin{cases} a & x > 0 \\ b & x \le 0 \end{cases}',
      'Cases'),
];

const List<PaeMathSymbolGroup> kPaeMathSymbolGroups = [
  PaeMathSymbolGroup('Operators', [
    PaeMathSymbol('+', 'Plus'),
    PaeMathSymbol('−', 'Minus', '-'),
    PaeMathSymbol('×', 'Times', r'\times'),
    PaeMathSymbol('÷', 'Divide', r'\div'),
    PaeMathSymbol('±', 'Plus-minus', r'\pm'),
    PaeMathSymbol('∓', 'Minus-plus', r'\mp'),
    PaeMathSymbol('·', 'Dot', r'\cdot'),
    PaeMathSymbol('∗', 'Asterisk', r'\ast'),
    PaeMathSymbol('√', 'Square root', r'\sqrt{}'),
    PaeMathSymbol('∛', 'Cube root', r'\sqrt[3]{}'),
    PaeMathSymbol('∑', 'Sum', r'\sum'),
    PaeMathSymbol('∏', 'Product', r'\prod'),
    PaeMathSymbol('∫', 'Integral', r'\int'),
    PaeMathSymbol('∬', 'Double integral', r'\iint'),
    PaeMathSymbol('∮', 'Contour integral', r'\oint'),
    PaeMathSymbol('∂', 'Partial', r'\partial'),
    PaeMathSymbol('∇', 'Nabla', r'\nabla'),
    PaeMathSymbol('∞', 'Infinity', r'\infty'),
    PaeMathSymbol('°', 'Degree', r'^{\circ}'),
    PaeMathSymbol('′', 'Prime', "'"),
    PaeMathSymbol('%', 'Percent', r'\%'),
    PaeMathSymbol('‰', 'Per mille'),
  ]),
  PaeMathSymbolGroup('Relations', [
    PaeMathSymbol('=', 'Equals'),
    PaeMathSymbol('≠', 'Not equal', r'\neq'),
    PaeMathSymbol('≈', 'Approximately', r'\approx'),
    PaeMathSymbol('≡', 'Identical', r'\equiv'),
    PaeMathSymbol('≅', 'Congruent', r'\cong'),
    PaeMathSymbol('∼', 'Similar', r'\sim'),
    PaeMathSymbol('∝', 'Proportional', r'\propto'),
    PaeMathSymbol('<', 'Less than'),
    PaeMathSymbol('>', 'Greater than'),
    PaeMathSymbol('≤', 'Less or equal', r'\leq'),
    PaeMathSymbol('≥', 'Greater or equal', r'\geq'),
    PaeMathSymbol('≪', 'Much less', r'\ll'),
    PaeMathSymbol('≫', 'Much greater', r'\gg'),
  ]),
  PaeMathSymbolGroup('Greek', [
    PaeMathSymbol('α', 'alpha', r'\alpha'),
    PaeMathSymbol('β', 'beta', r'\beta'),
    PaeMathSymbol('γ', 'gamma', r'\gamma'),
    PaeMathSymbol('δ', 'delta', r'\delta'),
    PaeMathSymbol('ε', 'epsilon', r'\epsilon'),
    PaeMathSymbol('ζ', 'zeta', r'\zeta'),
    PaeMathSymbol('η', 'eta', r'\eta'),
    PaeMathSymbol('θ', 'theta', r'\theta'),
    PaeMathSymbol('λ', 'lambda', r'\lambda'),
    PaeMathSymbol('μ', 'mu', r'\mu'),
    PaeMathSymbol('ξ', 'xi', r'\xi'),
    PaeMathSymbol('π', 'pi', r'\pi'),
    PaeMathSymbol('ρ', 'rho', r'\rho'),
    PaeMathSymbol('σ', 'sigma', r'\sigma'),
    PaeMathSymbol('τ', 'tau', r'\tau'),
    PaeMathSymbol('φ', 'phi', r'\phi'),
    PaeMathSymbol('χ', 'chi', r'\chi'),
    PaeMathSymbol('ψ', 'psi', r'\psi'),
    PaeMathSymbol('ω', 'omega', r'\omega'),
    PaeMathSymbol('Γ', 'Gamma', r'\Gamma'),
    PaeMathSymbol('Δ', 'Delta', r'\Delta'),
    PaeMathSymbol('Θ', 'Theta', r'\Theta'),
    PaeMathSymbol('Λ', 'Lambda', r'\Lambda'),
    PaeMathSymbol('Π', 'Pi', r'\Pi'),
    PaeMathSymbol('Σ', 'Sigma', r'\Sigma'),
    PaeMathSymbol('Φ', 'Phi', r'\Phi'),
    PaeMathSymbol('Ψ', 'Psi', r'\Psi'),
    PaeMathSymbol('Ω', 'Omega', r'\Omega'),
  ]),
  PaeMathSymbolGroup('Sets & Logic', [
    PaeMathSymbol('∈', 'Element of', r'\in'),
    PaeMathSymbol('∉', 'Not element of', r'\notin'),
    PaeMathSymbol('⊂', 'Subset', r'\subset'),
    PaeMathSymbol('⊃', 'Superset', r'\supset'),
    PaeMathSymbol('⊆', 'Subset or equal', r'\subseteq'),
    PaeMathSymbol('⊇', 'Superset or equal', r'\supseteq'),
    PaeMathSymbol('∪', 'Union', r'\cup'),
    PaeMathSymbol('∩', 'Intersection', r'\cap'),
    PaeMathSymbol('∅', 'Empty set', r'\emptyset'),
    PaeMathSymbol('ℕ', 'Naturals', r'\mathbb{N}'),
    PaeMathSymbol('ℤ', 'Integers', r'\mathbb{Z}'),
    PaeMathSymbol('ℚ', 'Rationals', r'\mathbb{Q}'),
    PaeMathSymbol('ℝ', 'Reals', r'\mathbb{R}'),
    PaeMathSymbol('ℂ', 'Complex', r'\mathbb{C}'),
    PaeMathSymbol('∀', 'For all', r'\forall'),
    PaeMathSymbol('∃', 'Exists', r'\exists'),
    PaeMathSymbol('¬', 'Not', r'\neg'),
    PaeMathSymbol('∧', 'And', r'\land'),
    PaeMathSymbol('∨', 'Or', r'\lor'),
    PaeMathSymbol('∴', 'Therefore', r'\therefore'),
    PaeMathSymbol('∵', 'Because', r'\because'),
  ]),
  PaeMathSymbolGroup('Arrows', [
    PaeMathSymbol('→', 'Right arrow', r'\to'),
    PaeMathSymbol('←', 'Left arrow', r'\leftarrow'),
    PaeMathSymbol('↔', 'Left-right arrow', r'\leftrightarrow'),
    PaeMathSymbol('⇒', 'Implies', r'\Rightarrow'),
    PaeMathSymbol('⇐', 'Implied by', r'\Leftarrow'),
    PaeMathSymbol('⇔', 'If and only if', r'\Leftrightarrow'),
    PaeMathSymbol('↑', 'Up arrow', r'\uparrow'),
    PaeMathSymbol('↓', 'Down arrow', r'\downarrow'),
    PaeMathSymbol('↦', 'Maps to', r'\mapsto'),
  ]),
  PaeMathSymbolGroup('Geometry', [
    PaeMathSymbol('∠', 'Angle', r'\angle'),
    PaeMathSymbol('⊥', 'Perpendicular', r'\perp'),
    PaeMathSymbol('∥', 'Parallel', r'\parallel'),
    PaeMathSymbol('△', 'Triangle', r'\triangle'),
    PaeMathSymbol('□', 'Square', r'\square'),
    PaeMathSymbol('○', 'Circle', r'\circ'),
    PaeMathSymbol('⌒', 'Arc', r'\frown'),
  ]),
  PaeMathSymbolGroup('Super / Subscript', [
    PaeMathSymbol('⁰', 'Superscript 0', '^{0}'),
    PaeMathSymbol('¹', 'Superscript 1', '^{1}'),
    PaeMathSymbol('²', 'Squared', '^{2}'),
    PaeMathSymbol('³', 'Cubed', '^{3}'),
    PaeMathSymbol('⁴', 'Superscript 4', '^{4}'),
    PaeMathSymbol('⁵', 'Superscript 5', '^{5}'),
    PaeMathSymbol('⁶', 'Superscript 6', '^{6}'),
    PaeMathSymbol('⁷', 'Superscript 7', '^{7}'),
    PaeMathSymbol('⁸', 'Superscript 8', '^{8}'),
    PaeMathSymbol('⁹', 'Superscript 9', '^{9}'),
    PaeMathSymbol('⁺', 'Superscript plus', '^{+}'),
    PaeMathSymbol('⁻', 'Superscript minus', '^{-}'),
    PaeMathSymbol('ⁿ', 'Superscript n', '^{n}'),
    PaeMathSymbol('₀', 'Subscript 0', '_{0}'),
    PaeMathSymbol('₁', 'Subscript 1', '_{1}'),
    PaeMathSymbol('₂', 'Subscript 2', '_{2}'),
    PaeMathSymbol('₃', 'Subscript 3', '_{3}'),
    PaeMathSymbol('₄', 'Subscript 4', '_{4}'),
    PaeMathSymbol('ₙ', 'Subscript n', '_{n}'),
  ]),
  PaeMathSymbolGroup('Fractions', [
    PaeMathSymbol('½', 'One half', r'\frac{1}{2}'),
    PaeMathSymbol('⅓', 'One third', r'\frac{1}{3}'),
    PaeMathSymbol('⅔', 'Two thirds', r'\frac{2}{3}'),
    PaeMathSymbol('¼', 'One quarter', r'\frac{1}{4}'),
    PaeMathSymbol('¾', 'Three quarters', r'\frac{3}{4}'),
    PaeMathSymbol('⅕', 'One fifth', r'\frac{1}{5}'),
    PaeMathSymbol('⅛', 'One eighth', r'\frac{1}{8}'),
  ]),
];
