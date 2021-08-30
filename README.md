# Kombinator

[![The MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](http://opensource.org/licenses/MIT)
[![Continuous integration](https://github.com/dourouc05/Kombinator.jl/actions/workflows/GitHubCI.yml/badge.svg)](https://github.com/dourouc05/Kombinator.jl/actions/workflows/GitHubCI.yml/)
[![Coverage](https://codecov.io/gh/dourouc05/Kombinator.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dourouc05/Kombinator.jl)
[![Coverage](https://coveralls.io/repos/github/dourouc05/Kombinator.jl/badge.svg?branch=master)](https://coveralls.io/github/dourouc05/Kombinator.jl?branch=master)

This package implements several combinatorial-optimisation algorithms with a common interface. Unlike tools like [JuMP](https://jump.dev/), it only focuses on the structure of the problem and does not provide a generic means of performing combinatorial optimisation, with the benefit of having no external dependency and having great runtime performance.

To install:

```julia
]add Kombinator
```

## Citing

If you use this package in your research, please cite the article introducing the novel algorithms implemented in this package: 

```bibtex
@article{cuvelier2021aescb,
    author = {Cuvelier, Thibaut and Combes, Richard and Gourdin, Eric},
    title = {Statistically Efficient, Polynomial-Time Algorithms for Combinatorial Semi-Bandits},
    year = {2021},
    issue_date = {March 2021},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    volume = {5},
    number = {1},
    url = {https://doi.org/10.1145/3447387},
    doi = {10.1145/3447387},
    journal = {Proc. ACM Meas. Anal. Comput. Syst.},
    month = feb,
    articleno = {09},
    numpages = {31},
    keywords = {combinatorial bandits, combinatorial optimization, bandits}
}
```
