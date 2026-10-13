/// A single math symbol: the Unicode character pasted as text, and its LaTeX
/// command used inside formulas.
class MathSymbol {
  const MathSymbol(this.char, this.name, [this.latex]);

  final String char;
  final String name;
  final String? latex;

  String get latexOrChar => latex ?? char;
}

class MathSymbolGroup {
  const MathSymbolGroup(this.title, this.symbols);

  final String title;
  final List<MathSymbol> symbols;
}

/// A LaTeX snippet inserted from the formula panel.
class MathTemplate {
  const MathTemplate(this.label, this.latex, this.tooltip);

  final String label;
  final String latex;
  final String tooltip;
}

const List<MathTemplate> kMathTemplates = [
  MathTemplate('a⁄b', r'\frac{a}{b}', 'Fraction'),
  MathTemplate('√x', r'\sqrt{x}', 'Square root'),
  MathTemplate('ⁿ√x', r'\sqrt[n]{x}', 'n-th root'),
  MathTemplate('xⁿ', r'x^{n}', 'Power'),
  MathTemplate('xₙ', r'x_{n}', 'Subscript'),
  MathTemplate('∑', r'\sum_{i=1}^{n} ', 'Sum'),
  MathTemplate('∏', r'\prod_{i=1}^{n} ', 'Product'),
  MathTemplate('∫', r'\int_{a}^{b} f(x)\,dx', 'Integral'),
  MathTemplate('lim', r'\lim_{x \to \infty} ', 'Limit'),
  MathTemplate('d/dx', r'\frac{d}{dx}', 'Derivative'),
  MathTemplate('log', r'\log_{b}(x)', 'Logarithm'),
  MathTemplate('( )', r'\left( x \right)', 'Parentheses'),
  MathTemplate('|x|', r'\left| x \right|', 'Absolute value'),
  MathTemplate('x̄', r'\overline{x}', 'Overline'),
  MathTemplate('v⃗', r'\vec{v}', 'Vector'),
  MathTemplate('[ ]', r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
      'Matrix'),
  MathTemplate('{ }', r'f(x) = \begin{cases} a & x > 0 \\ b & x \le 0 \end{cases}',
      'Cases'),
];

const List<MathSymbolGroup> kMathSymbolGroups = [
  MathSymbolGroup('Operators', [
    MathSymbol('+', 'Plus'),
    MathSymbol('−', 'Minus', '-'),
    MathSymbol('×', 'Times', r'\times'),
    MathSymbol('÷', 'Divide', r'\div'),
    MathSymbol('±', 'Plus-minus', r'\pm'),
    MathSymbol('∓', 'Minus-plus', r'\mp'),
    MathSymbol('·', 'Dot', r'\cdot'),
    MathSymbol('∗', 'Asterisk', r'\ast'),
    MathSymbol('√', 'Square root', r'\sqrt{}'),
    MathSymbol('∛', 'Cube root', r'\sqrt[3]{}'),
    MathSymbol('∑', 'Sum', r'\sum'),
    MathSymbol('∏', 'Product', r'\prod'),
    MathSymbol('∫', 'Integral', r'\int'),
    MathSymbol('∬', 'Double integral', r'\iint'),
    MathSymbol('∮', 'Contour integral', r'\oint'),
    MathSymbol('∂', 'Partial', r'\partial'),
    MathSymbol('∇', 'Nabla', r'\nabla'),
    MathSymbol('∞', 'Infinity', r'\infty'),
    MathSymbol('°', 'Degree', r'^{\circ}'),
    MathSymbol('′', 'Prime', "'"),
    MathSymbol('%', 'Percent', r'\%'),
    MathSymbol('‰', 'Per mille'),
  ]),
  MathSymbolGroup('Relations', [
    MathSymbol('=', 'Equals'),
    MathSymbol('≠', 'Not equal', r'\neq'),
    MathSymbol('≈', 'Approximately', r'\approx'),
    MathSymbol('≡', 'Identical', r'\equiv'),
    MathSymbol('≅', 'Congruent', r'\cong'),
    MathSymbol('∼', 'Similar', r'\sim'),
    MathSymbol('∝', 'Proportional', r'\propto'),
    MathSymbol('<', 'Less than'),
    MathSymbol('>', 'Greater than'),
    MathSymbol('≤', 'Less or equal', r'\leq'),
    MathSymbol('≥', 'Greater or equal', r'\geq'),
    MathSymbol('≪', 'Much less', r'\ll'),
    MathSymbol('≫', 'Much greater', r'\gg'),
  ]),
  MathSymbolGroup('Greek', [
    MathSymbol('α', 'alpha', r'\alpha'),
    MathSymbol('β', 'beta', r'\beta'),
    MathSymbol('γ', 'gamma', r'\gamma'),
    MathSymbol('δ', 'delta', r'\delta'),
    MathSymbol('ε', 'epsilon', r'\epsilon'),
    MathSymbol('ζ', 'zeta', r'\zeta'),
    MathSymbol('η', 'eta', r'\eta'),
    MathSymbol('θ', 'theta', r'\theta'),
    MathSymbol('λ', 'lambda', r'\lambda'),
    MathSymbol('μ', 'mu', r'\mu'),
    MathSymbol('ξ', 'xi', r'\xi'),
    MathSymbol('π', 'pi', r'\pi'),
    MathSymbol('ρ', 'rho', r'\rho'),
    MathSymbol('σ', 'sigma', r'\sigma'),
    MathSymbol('τ', 'tau', r'\tau'),
    MathSymbol('φ', 'phi', r'\phi'),
    MathSymbol('χ', 'chi', r'\chi'),
    MathSymbol('ψ', 'psi', r'\psi'),
    MathSymbol('ω', 'omega', r'\omega'),
    MathSymbol('Γ', 'Gamma', r'\Gamma'),
    MathSymbol('Δ', 'Delta', r'\Delta'),
    MathSymbol('Θ', 'Theta', r'\Theta'),
    MathSymbol('Λ', 'Lambda', r'\Lambda'),
    MathSymbol('Π', 'Pi', r'\Pi'),
    MathSymbol('Σ', 'Sigma', r'\Sigma'),
    MathSymbol('Φ', 'Phi', r'\Phi'),
    MathSymbol('Ψ', 'Psi', r'\Psi'),
    MathSymbol('Ω', 'Omega', r'\Omega'),
  ]),
  MathSymbolGroup('Sets & Logic', [
    MathSymbol('∈', 'Element of', r'\in'),
    MathSymbol('∉', 'Not element of', r'\notin'),
    MathSymbol('⊂', 'Subset', r'\subset'),
    MathSymbol('⊃', 'Superset', r'\supset'),
    MathSymbol('⊆', 'Subset or equal', r'\subseteq'),
    MathSymbol('⊇', 'Superset or equal', r'\supseteq'),
    MathSymbol('∪', 'Union', r'\cup'),
    MathSymbol('∩', 'Intersection', r'\cap'),
    MathSymbol('∅', 'Empty set', r'\emptyset'),
    MathSymbol('ℕ', 'Naturals', r'\mathbb{N}'),
    MathSymbol('ℤ', 'Integers', r'\mathbb{Z}'),
    MathSymbol('ℚ', 'Rationals', r'\mathbb{Q}'),
    MathSymbol('ℝ', 'Reals', r'\mathbb{R}'),
    MathSymbol('ℂ', 'Complex', r'\mathbb{C}'),
    MathSymbol('∀', 'For all', r'\forall'),
    MathSymbol('∃', 'Exists', r'\exists'),
    MathSymbol('¬', 'Not', r'\neg'),
    MathSymbol('∧', 'And', r'\land'),
    MathSymbol('∨', 'Or', r'\lor'),
    MathSymbol('∴', 'Therefore', r'\therefore'),
    MathSymbol('∵', 'Because', r'\because'),
  ]),
  MathSymbolGroup('Arrows', [
    MathSymbol('→', 'Right arrow', r'\to'),
    MathSymbol('←', 'Left arrow', r'\leftarrow'),
    MathSymbol('↔', 'Left-right arrow', r'\leftrightarrow'),
    MathSymbol('⇒', 'Implies', r'\Rightarrow'),
    MathSymbol('⇐', 'Implied by', r'\Leftarrow'),
    MathSymbol('⇔', 'If and only if', r'\Leftrightarrow'),
    MathSymbol('↑', 'Up arrow', r'\uparrow'),
    MathSymbol('↓', 'Down arrow', r'\downarrow'),
    MathSymbol('↦', 'Maps to', r'\mapsto'),
  ]),
  MathSymbolGroup('Geometry', [
    MathSymbol('∠', 'Angle', r'\angle'),
    MathSymbol('⊥', 'Perpendicular', r'\perp'),
    MathSymbol('∥', 'Parallel', r'\parallel'),
    MathSymbol('△', 'Triangle', r'\triangle'),
    MathSymbol('□', 'Square', r'\square'),
    MathSymbol('○', 'Circle', r'\circ'),
    MathSymbol('⌒', 'Arc', r'\frown'),
  ]),
  MathSymbolGroup('Super / Subscript', [
    MathSymbol('⁰', 'Superscript 0', '^{0}'),
    MathSymbol('¹', 'Superscript 1', '^{1}'),
    MathSymbol('²', 'Squared', '^{2}'),
    MathSymbol('³', 'Cubed', '^{3}'),
    MathSymbol('⁴', 'Superscript 4', '^{4}'),
    MathSymbol('⁵', 'Superscript 5', '^{5}'),
    MathSymbol('⁶', 'Superscript 6', '^{6}'),
    MathSymbol('⁷', 'Superscript 7', '^{7}'),
    MathSymbol('⁸', 'Superscript 8', '^{8}'),
    MathSymbol('⁹', 'Superscript 9', '^{9}'),
    MathSymbol('⁺', 'Superscript plus', '^{+}'),
    MathSymbol('⁻', 'Superscript minus', '^{-}'),
    MathSymbol('ⁿ', 'Superscript n', '^{n}'),
    MathSymbol('₀', 'Subscript 0', '_{0}'),
    MathSymbol('₁', 'Subscript 1', '_{1}'),
    MathSymbol('₂', 'Subscript 2', '_{2}'),
    MathSymbol('₃', 'Subscript 3', '_{3}'),
    MathSymbol('₄', 'Subscript 4', '_{4}'),
    MathSymbol('ₙ', 'Subscript n', '_{n}'),
  ]),
  MathSymbolGroup('Fractions', [
    MathSymbol('½', 'One half', r'\frac{1}{2}'),
    MathSymbol('⅓', 'One third', r'\frac{1}{3}'),
    MathSymbol('⅔', 'Two thirds', r'\frac{2}{3}'),
    MathSymbol('¼', 'One quarter', r'\frac{1}{4}'),
    MathSymbol('¾', 'Three quarters', r'\frac{3}{4}'),
    MathSymbol('⅕', 'One fifth', r'\frac{1}{5}'),
    MathSymbol('⅛', 'One eighth', r'\frac{1}{8}'),
  ]),
];
