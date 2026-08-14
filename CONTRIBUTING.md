# Contributing to SDR Project

Thank you for your interest in contributing to the Software-Defined Radio project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs
1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (hardware, software versions)
   - Relevant logs/screenshots

### Suggesting Enhancements
1. Check existing feature requests
2. Provide detailed description of the enhancement
3. Explain the use case and benefits
4. Consider if you can implement it yourself

### Code Contributions

#### FPGA Design (Verilog)
- Follow existing coding style and conventions
- Add testbenches for new modules
- Update documentation
- Ensure timing constraints are met
- Test with simulation before submission

#### Embedded Software (C)
- Follow existing code style
- Add comments for complex logic
- Update function documentation
- Test on target hardware when possible
- Ensure memory safety

#### PC Software (Python)
- Follow PEP 8 style guide
- Add docstrings to functions
- Update requirements.txt if needed
- Test with Python 3.8+
- Maintain GUI consistency

## Development Workflow

### Setting Up Development Environment
1. Fork the repository
2. Clone your fork locally
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

### Branch Naming
- `feature/` - New features
- `bugfix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test additions
- `refactor/` - Code refactoring

### Commit Messages
Follow conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat(fpga): add IIR filter module with biquad sections

Implements cascaded biquad IIR filter with configurable
coefficients and dynamic range scaling.

Closes #123
```

## Testing Requirements

### FPGA Testing
- All modules must have testbenches
- Achieve >90% code coverage
- Pass timing analysis
- Verify resource usage

### Embedded Testing
- Unit tests for all functions
- Integration tests for hardware interfaces
- Memory leak detection
- Real-time performance validation

### Software Testing
- Unit tests for all modules
- GUI automated tests
- Integration tests with mock hardware
- Performance benchmarks

## Code Review Process

### Before Submitting
- Self-review your code
- Update documentation
- Add/update tests
- Ensure all tests pass
- Update CHANGELOG if applicable

### During Review
- Respond to feedback promptly
- Make requested changes
- Explain complex decisions
- Keep discussions constructive

### After Approval
- Maintain your branch
- Address post-merge issues
- Update documentation as needed

## Documentation Standards

### Code Comments
- Explain "why" not "what"
- Keep comments current
- Use clear, concise language
- Avoid obvious comments

### README Updates
- Update architecture diagrams
- Add new features to feature list
- Update build instructions
- Add performance metrics

### API Documentation
- Document all public functions
- Include parameter descriptions
- Provide usage examples
- Note any limitations

## Performance Guidelines

### FPGA Design
- Target 50+ MHz clock frequency
- Minimize DSP slice usage
- Optimize memory bandwidth
- Consider power consumption

### Embedded Software
- Minimize memory usage
- Optimize for real-time performance
- Use efficient algorithms
- Consider cache effects

### PC Software
- Maintain responsive GUI
- Optimize data processing
- Minimize memory footprint
- Profile critical paths

## Security Considerations

### Input Validation
- Validate all external inputs
- Sanitize user data
- Handle edge cases
- Prevent buffer overflows

### Communication Security
- Encrypt sensitive data
- Authenticate connections
- Validate protocols
- Log security events

## Release Process

### Version Numbering
Follow semantic versioning: `MAJOR.MINOR.PATCH`
- MAJOR: Incompatible changes
- MINOR: New features (backwards compatible)
- PATCH: Bug fixes (backwards compatible)

### Release Checklist
- Update version number
- Update CHANGELOG
- Tag release in git
- Update documentation
- Create release notes
- Test release artifacts

## Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Acknowledge contributions

### Communication
- Use clear, professional language
- Provide context for discussions
- Be patient with questions
- Share knowledge freely

## Getting Help

### Resources
- Documentation in `/docs` directory
- Example code in testbenches
- Architecture diagrams in README
- Hardware requirements guide

### Contact
- Open GitHub issues for bugs/questions
- Use discussions for general topics
- Join community chat (if available)
- Check existing issues first

## Recognition

### Contributors
All contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

### Significant Contributions
Notable contributions may be highlighted in:
- Project README
- Blog posts
- Conference presentations

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to the SDR project! Your contributions help make this project better for everyone.
