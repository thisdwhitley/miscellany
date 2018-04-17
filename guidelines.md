# Guidelines
## ***[WIP] This is a work in progress...and probably always will be[WIP]***
This is my attempt at a "style" guide.  It is originally intended for Ansible,
but might eventually include other items as well so I will leave the title
purposely generic.

It is important to note that my work may not currently comply with all style
guide rules within, but the intention is that it will eventually.  It is really
going to be just for my reference and an attempt at standardization (which
historically fails as I learn more and adopt different techniques...).

Also note that this is largely personal.

## Table of Contents
* [1 Ansible](#1-ansible)
  * [1.1 Maximum line length](#11-maximum-line-length)
  * [1.2 File extensions](#12-file-extensions)
  * 1.3 Variables
  * [1.4 Module usage](#14-module-usage)
  * 1.5 Playbook formatting
  * 1.6 Whitespaces
  * [1.7 Booleans](#17-booleans)
* [2 References](#2-references)
---
## 1 Ansible
I hope I refer to this often, or at least until it becomes second nature.

---

### 1.1 Maximum line length

Ansible relies heavily on Python, so I will borrow from [Pep8](https://www.python.org/dev/peps/pep-0008/#maximum-line-length):
#### 1.1.1 All lines *SHOULD* be no longer than 80 characters

Every attempt SHOULD be made to comply with this soft line length limit, and only when it makes the code more readable should this be violated.

Code readability is subjective...

#### 1.1.2 All lines *MUST* be no longer than 120 characters
---
### 1.2 File extensions

#### 1.2.1 All Ansible Yaml files *MUST* have a .yml extension (and NOT .YML, .yaml etc)
Ansible tooling (like `ansible-galaxy init`) create files with a .yml extension. Also, the Ansible documentation website references files with a .yml extension several times. Because of this, it is normal in the Ansible community to use a .yml extension for all Ansible Yaml files.

This includes variables files that are in the Yaml format.

#### 1.2.2 All template files *MUST* have a .j2 extension
Because Ansible uses Jinja for templating... .j2

---
### 1.3 Variables
#### 1.3.1 CLI variables
#### 1.3.2 global variables
#### 1.3.3 role variables
#### 1.3.4 encrypted/vault variables
#### 1.3.5 general: use spaces

---
### 1.4 Module usage
#### 1.4.1 All modules *SHOULD* be supported
Every attempt SHOULD be made to use modules currently supported by the core team.  This list is ever changing so this will be difficult.  Additionally, there will just be times when this is not possible.

> [Modules Maintained by the Ansible Core Team](http://docs.ansible.com/ansible/latest/core_maintained.html)

---
### 1.5 Playbook formatting

---
### 1.6 Indentation

---
### 1.7 Booleans
#### 1.7.1 Booleans *SHOULD* be "true" or "false"
Ansible allows you to specify a boolean value (true/false) in several forms.  In general, values of **true** and **false** SHOULD be used unless it reads awkwardly.

---
## 2 References
* [openshift-ansible Style Guide](https://github.com/openshift/openshift-ansible/blob/master/docs/style_guide.adoc)
* [Ansible - Best Practices](http://docs.ansible.com/ansible/latest/playbooks_best_practices.html)
* [Ansible - YAML Syntax](http://docs.ansible.com/ansible/latest/YAMLSyntax.html)
* [Ansible Best Practices: The Essentials](https://www.ansible.com/blog/ansible-best-practices-essentials)
