;;; epackage.el --- Distributed Emacs Lisp package system (DELPS)

;; This file is not part of Emacs

;; Copyright (C)    2009-2011 Jari Aalto
;; Keywords:        tools
;; Author:          Jari Aalto
;; Maintainer:      Jari Aalto

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.
;;
;; Visit <http://www.gnu.org/copyleft/gpl.html> for more information

;; Depends:

;;      o   Emacs 22.1+ (released 2007). Designed only for Emacs.
;;          XEmacs has its own packaging system (pui-*).
;;          http://www.gnu.org/software/emacs
;;      o   git(1) Distributed Version Control System (DVCS). Any version.
;;          http://en.wikipedia.org/wiki/Git_(software)
;;      o   Depends only on standard Emacs. Does not use cl.

;;; Install:

;;
;;  Put this file on your Emacs-Lisp `load-path', add following into your
;;  ~/.emacs startup file.
;;
;;      ;;  M-x epackage to start installing, upgrading. removing
;;      (autoload 'epackage "epackage" "" t)
;;
;;      ;; One big file to boot all packages (auto generated)
;;      (load "~/.emacs.d/epackage/00link/epackage-loader" 'noerr)

;;; Commentary:

;;  Preface 2009
;;
;;      Emacs has been around for decades now. Many new version have
;;      come and gone (18.59 ... 24.x), Still there are wealth of
;;      extensions found e.g. from <http://emacswiki.org> that enhance
;;      and add new features. The typical procedure to add new a
;;      extension to Emacs is:
;;
;;      o   Find an extension at places like
;;          http://dir.gmane.org/gmane.emacs.sources or
;;          http://www.emacswiki.org
;;      o   Download and save the *.el file along `load-path'
;;      o   Read the installation information. Usually embedded in comments
;;          at the beginning of *.el files.
;;      o   Add code to the Emacs startup file ~/.emacs
;;          to arrange loading the extension to your liking.
;;
;;      That's quite a bit of work for each extension; reaching
;;      thousands out there. Many Linux distributions offer package
;;      managers to download and install programs. E.g. Debian has
;;      command *apt-get*, Redhat uses *rpm*, Suse uses *yum*. So why
;;      not make one for Emacs as well.
;;
;;      This utility is different from the existing ELPA Emacs package
;;      manager. It has been built around two concepts: 1) it borrows
;;      the Debian style of package management and applies it to Emacs
;;      packages. The main idea is being distributed in nature; not
;;      centralized like ELPA.
;;
;;      Each Emacs extension is cnoverted into epackage format, which
;;      means including Debians tyle control directory epackge/ where
;;      all the details about activation, autoloads and installation
;;      are kept. The seond concept is that each epackage is imported
;;      and distributed using Git Distributed Version Control System
;;      (DVCS). After initial load of an epackage repository, the
;;      subsequent downloads are ver efficient because only deltas are
;;      trasferred. Another benefit of DVCS is its distributed nature:
;;      local modifications are possible, all the software history and
;;      releases are included in the repository. This give some
;;      interesting prospects and freedom to maintain and deploy
;;      epackages from anywhere.
;;
;;      If you're an Emacs user, all these details do not concern you.
;;      From package management view, select packages to downlaod, and
;;      they appear in your local disk. You have several options how
;;      to proceed from theree: select autoload install (no Emacs
;;      changes), or activation (Emacs environment is changed). Later
;;      you can upgrade packages and periodically download epackage
;;      list to see what new has been made available,

;;      If you're a Emacs extension developer who would like to start
;;      distributing your work in epackage format, that will require
;;      familiarizing with the git(1).
;;
;;      This package manager can co-exist with nay other installation
;;      as usual. It is possible to use other package managers, like
;;      ELPA, at the same time. User's standard Emacs startup files,
;;      like ~/.emacs are never modified.
;;
;;  Epackage - the DVCS packaging system
;;
;;      This packaging system is called epackage, short name for
;;      "Emacs Lisp packages".
;;
;;      In this system packages are available in a form of
;;      distributed[1] git[2] version control repositories. The
;;      traditional packaging methods (like ELPA[2]) have previously
;;      relied on archives like *.tar.gz to hold the code. In contrast
;;      the DVCS offers important features over monolithic archive
;;      approach:
;;
;;      o   Efficient downloads; fast, only deltas are transferred.
;;      o   Local modifications; users can create their own customizations
;;          and track them easily,
;;      o   Helping package authors made easy; have you found an error?
;;          Have a spare time to fix it? Generate diff straight from the
;;          version control repository.
;;      o   Select any version; pick latest or
;;          downgrade to a older version with ease.
;;      o   Contains history of package in one place. No more scattered
;;          pieces around Internet.
;;
;;      The Emacs extensions need to prepared for use with this
;;      system: imported to git, the repository must be made available
;;      online and information about the avilability must be submitted
;;      to epackage sources list, the "yellow pages". This job can be
;;      done by anyone who wants to set up a reposository. It doesn't
;;      need to be done by the original Emacs extension author
;;      (upstream) who may not be familiar with the git(1) program.
;;      For more inforamtion about the packaging see following topics.
;;
;;      [1] DVCS = Distributed Version Control System
;;          http://en.wikipedia.org/wiki/Distributed_revision_control
;;
;;      [2] http://git-scm.org
;;
;;      [3] http://www.emacswiki.org/emacs/ELPA
;;
;;  User commands
;;
;;      Command `M-x' `epackage' is alias for function
;;      `epackage-manager'. It builds buffer where packages can be
;;      browsed, fetched, built and installed. The view contains:
;;
;;          [mode indicators]
;;
;;          name section status v:VERSION package-description
;;          1    2       3      4         5
;;
;;      Mode indicators are:
;;
;;      o   compile - byte compile package on install phase.
;;      o   activate|enable - Auto-enable or activate on install phase
;;          See "status" for more explanation.
;;
;;      The fields are:
;;
;;      o   1 - Unique package name. No two package scan have the same name.
;;      o   2 - Package classification. M-x finder-list-keywords
;;      o   3 - status: (A)activated (E)nabled (I)installed etc.
;;      o   4 - Version number. Only known once package has been downloaded.
;;      o   5 - Short package description
;;
;;      In this view, some of the commands are (see mode help `C-h' `m'):
;;
;;      o   d, run `dired' on package installation directory.
;;      o   e, edit package's *info* file.
;;      o   E, email upstream, the package author (maintainer). You can
;;             as for new wishlist features, report bugs etc.
;;      o   g, get. Update avaiĺable package list.
;;      o   i, install package.
;;      o   l, list only installed packages.
;;      o   m, mark package (for command install or remove).
;;      o   M, send mail to person who is the maintainer of epackage
;;             for this utility. You can send requests to fix
;;             packaging or update contents of the 'info' file if some
;;             of the information in no up to date.
;;      o   n, list only new packages (not-installed).
;;      o   p, purge package; delete package physically from local disk.
;;      o   r, remove package. Synonym for uninstall action.
;;      o   s<key>, sort command. Change listing by several criterias.
;;      o   u, unmark (install, purge, remove).
;;      o   U, upgrade package to newer version.
;;      o   v<key>, view comand. E.g (a)activation file, (i)info file.
;;      o   q, quit. Run `bury-buffer'.
;;      o   x, execute (install, purge, remove).
;;
;;      The package state is shows with following status indiators:
;;
;;      o   (A)ctivated. The package has been downloaded and code to
;;          immediately activate the package has been taken into use.
;;          This setting chnages user's Emacs environment as defined
;;          by the packager. The chnages typically include modifying hook
;;          to activate the package e.g. by file extension, adding
;;          keybindings to activate the package etc. You might want
;;          to use (v)iew command to see what exactly happens
;;      o   (E)enabled. One step down from Activated state. Only interactive
;;          functions and variables are provided in latent `autoload'
;;          stae for user to call with `M-x' <function name>. User
;;          configuration is not modified in any way.If you want full
;;          control over package setup, set package to Emabled state
;;          and add further code to Emacs startup file "/.emacs to
;;          configure it
;;      o   (I)installed. This is synonym for Downloaded. Package has
;;          been fetched to local disk, but that is all. No setup
;;          whatsoever.
;;      o   (u)unmaintained. The package has been flagged as unmaintained.
;;      o   (b)uggy. The package contains remarks that it might be buggy
;;          if installed.
;;      o   (c)ompiled. Package has been byte compiled.
;;      o   (e)macs core. Package in included in latest core Emacs.
;;      o   (x)emacs core. Package is included in latest core XEmacs.
;;
;;      Building the initial list of available packages takes some time
;;      and this is done via open internet connection. Install command
;;      also requires an open internet connection.
;;
;;  The epackage system framework
;;
;;      To epxlain how do all the pieces in this system go together,
;;      lets take a look at the system overview. The system mirrors
;;      the style of Debian packaging management. There are two
;;      primary actors: (1) the epackage package maintainer and (2)
;;      the upstream. These two can be the same person or two separate
;;      persons.
;;
;;      o   A = An Emacs user who wannts to install new software
;;      o   (Y)ellow pages = The sources list file that contains
;;          information about available epakages around the globe.
;;      o   E = The epackage. Maintained by a person who has found an
;;          interesting utility and wrapped it in epackage format. He
;;          is the maintainer of epackaged software. He keeps
;;          track of new releases and makes new epackages periodically
;;          available. If the initial packager looses interest,
;;          someone else can continue his work. He supplies the *url*
;;          to the "Yellow pages" to notify about availability of epackage.
;;      o   U = Upstream. Person or team who wrote Emacs Lisp extension,
;;          the code or utility than enhances Emacs.
;;
;;      The moving parts communicate like in picture below. In order to
;;      find package, a "yellow pages" is consulted. It is seeded and
;;      update by all the epackage maintainer that wish to make epackages
;;      available. The user A does not need to know any details of this
;;      process; like in Debian, he justs "apt-get" install an epackage
;;      that is made newly available or which has been updated and is
;;      upgradeable.
;;
;;      o   The location of "Yellow pages" is fixed (%).
;;      o   The location of E's and U's can be anywhere (*).
;;      o   The E and U can be the same person (the upstream).
;;
;;                      %               *               *
;;          A           Y               E               U
;;          =============================================
;;          |           |               | keep eye on   |
;;          |  fetch    |               * ------------> |
;;          * --------> |               | <-----------  |
;;          | <-------- |               | epackage new  |
;;          |  upgrade  | keep epackage | releases      |
;;          |           | info in sync  |               |
;;          |           | <------------ *               |
;;          |           |   (url)       |               |
;;          |                           |               |
;;          |    install "X"            |               |
;;          * ------------------------> |               |
;;          | <------------------------ |               |
;;          |   DVCS repo download      |               |
;;          |                           |               |
;;          |    upgrade "X"            |               |
;;          * ------------------------> |               |
;;          | <------------------------ |               |
;;          |   download DVCS "delta"   |               |
;;          |                           |               |
;;          |  report epackage bug      |               |
;;          * ------------------------> |               |
;;          |  report program bug       |               |
;;          * ----------------------------------------> |
;;          |                           |               |
;;          =============================================
;;
;;
;;  User's local epackage system layout
;;
;;      The packages are installed under root `epackage--root-directory',
;;      which defaults to ~/.emacs.d or ~/elisp respectively. The
;;      root directory is organized as follows:
;;
;;          epackage
;;          |
;;          +-- 00link/
;;          |   epackage-loader.el      One big boot file
;;          |   *.el *.elc              Symlinks to ../vc/PACKAGE/*.el
;;          |
;;          +-- install/
;;          |   <package>-activate.el files
;;          |   <package>-install.el files
;;          |
;;          +--vc/     Packages. The Version control repositories.
;;             |
;;             +-- 00epackage/          Yellow pages: list of available packages
;;             +-- package/             Downloaded package
;;             +-- package2/
;;             +-- ...
;;
;;  Epackage specification (version 1)
;;
;;      The Git repository branches used are:
;;
;;      o   `master', required. Branched off from `upstream'. Adds directory
;;          `epackage/'. This contains everything to use the package.
;;      o   `patches', optional. Patches to `upstream' code, if any.
;;          this branch is merged to to `master'.
;;      o   `upstream', required. The original unmodified upstream code.
;;          Releases are tagged with label
;;          "upstream/YYYY-MM-DD[--VERSION]". The YYYY-MM-DD is the date of
;;          upstream release or best guess (if only year is known, use
;;          YYYY-01-01), and it is accompanied with optional "--VERSION" of
;;          the package. Not all packages include version information. The
;;          ISO 8601 date is needed so that the 1) release date is
;;          immediately available e.g. for post processing and 2) the tags
;;          sort nicely by date. An example: "upstream/2009-12-31--0.3"
;;
;;      Tha bove in pictures. The `master' and possible `patches' are
;;      alwasy rebased (R) on current upstream code. This picture
;;      makes sense only if you're familiar git(1):
;;
;;          upstream    * - o - o - o
;;                           \ R     \ (Rebase)
;;          master            \       o -  o - o - o =>
;;                             \          / (merge)
;;          patches             o  - o - o
;;
;;      The epackaging method borrows concept from the Debian where a
;;      separate control directory is used for package information.
;;      The directory name *epackage* is not configurable. The layout
;;      of epackaged Emacs extension is:
;;
;;          <Emacs extension root dir>
;;          |
;;          +- .git/                    Version control branches (see above)
;;          |
;;          +-- epackage/
;;              info                    required: The package control file
;;              PACKAGE-0loaddefs.el    optional: ###autoload statements
;;              PACKAGE-autoloads.el    optional: all autoload statements (raw)
;;              PACKAGE-compile.el      optional: Code to byte compile package
;;              PACKAGE-install.el      required: Code to make package available
;;              PACKAGE-uninstall.el    optional: to remove package
;;              PACKAGE-xactivate.el    optional: Code to activate package
;;
;;      The nanes of the files have been chosen to sort
;;      alphabetically. All these configuration files are later
;;      combined in a gigantic loader, as you has chosen, to that
;;      Emacs will not spend time on loading individual files. Because
;;      the files list alphabetically, they can be combined safely
;;      together even on command line:
;;
;;              cat PACKAGE-* | egrep -v '00|uninst|compile' > PACKAGE-00.el
;;
;;     The *-0loaddefs.el
;;
;;      This file contains extracted ##autoload definitions. The file
;;      is suatomatically generated. The file does not modify user's
;;      environment. If PACKAGE does not contains any ###autoload
;;      definitions, the manually crafted *-install.el file works as a
;;      substitute. The "zero" at the start of the name is to help
;;      proper sorting ordering of all files.
;;
;;     The *-install.el
;;
;;      This file is manually written and it publishes user variables
;;      and interactive `M-x' functions in autoload states. The file
;;      does not modify user's environment. This file is necessary
;;      only if PACKAGE does not contain proper ###autoload statements
;;      (see *-0loaddefs.el). The "install" in name refers to
;;      installation or availability of interactive functions, not to
;;      any modifications to the system. Mnemonic: "if you load this
;;      file, you can start using package's features" (see
;;      *-activate.el).
;;
;;     The *-uninstall.el
;;
;;      This file does the opposite of *-install.el and *-activate.el
;;      It runs commands to remove the package as if it has never been
;;      loaded. Due to the nature of Emacs, it may not be possible to
;;      completely uninstall the package. The uninstallation covers
;;      undoing the changes to *-hook, *-functions and
;;      `auto-mode-alist' alike variables. The actual symbols (defined
;;      functions and variables) are not removed. Usually it is more
;;      practical to just restart Emacs than completely trying undo
;;      all the effects of a package.
;;
;;     The *-xactivate.el
;;
;;      This file makes the PACKAGE immediately active in user's
;;      environment. It can modify current environment by adding
;;      functions to hooks, adding minor or major modes or arranging
;;      keybindings so that when pressed, a feature is loaded and
;;      activated. It may also loop through `buffer-list' to activate
;;      features immediately in running Emacs. It is adviseable that
;;      any custom settings, like variables and prefix keys, are
;;      defined in `~/.emacs' *before* this file gets loaded.
;;      Mnemonic: "If you load this file, the bells and whistles are
;;      turned on". The "x" at the start of the name is to help proper
;;      sorting ordering of all files.
;;
;;  The info file
;;
;;      A RFC 2822 formatted file (email), which contains information about
;;      the package. The minumum required fields are presented below. The
;;      header field names are case insensitive. Continued lines must be
;;      indented; suggested indentation is 1 space. Required fields have
;;      been marked with asterisk (*). In the long description part, new
;;      paragraphs are separated by a single dot(.) character on their own
;;      line. The layout of the `info' mirrors concepts of `control' file in
;;      Debian packaging system (see
;;      <http://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version>).
;;
;;          *Package: <unique name, all lowercase>
;;          *Section: <data | extensions | files | languages | mail | tools | M-x finder-list-keywords>
;;          License: <GPL-[23]+ | BSD | Apache-2.0 | ... | None>
;;          *Depends: emacs (>= 20)
;;          Status: [ <keyword> ...]
;;          Compat: [ <epackage version> ]
;;          Maintainer: [ <epackage maintainer email> ]
;;          *Email: [ First Last <firts.last@example.com ]
;;          Bugs: [ URL ]
;;          Vcs-Type:
;;          Vcs-Url:
;;          Vcs-Args:
;;          Vcs-Browser:
;;          Vcs-User:
;;          Vcs-Password:
;;          Homepage:
;;          Wiki: http://www.emacswiki.org/emacs/<page name>
;;          X-<Field>-<Name>: [anything]
;;          *Description: <short one line>
;;           [<Longer description>]
;;           .
;;           [<Longer description, next paragraph>]
;;           .
;;           [<Longer description, next paragraph>]
;;
;;      An example:
;;
;;          Package: hide-lines
;;          Section: tools
;;          License: None
;;          Depends: emacs (>= 21)
;;          Status: unmaintained
;;          Compat:
;;          Maintainer:
;;          Email: Mark Hulme-Jones <ture@plig.net>
;;          Bugs:
;;          Vcs-Type: http
;;          Vcs-Url: http://www.emacswiki.org/emacs/download/hide-lines.el
;;          Vcs-Browser:
;;          Vcs-User:
;;          Vcs-Password:
;;          Homepage:
;;          Wiki: http://www.emacswiki.org/emacs/HideLines
;;          Description: Hide or preserve all matching lines in buffer
;;           Main command [C-u] M-x hide-lines to hide or show matching lines.
;;           With prefix argument, the corresponding lines are preserved while
;;           others are hidden.
;;           .
;;           Note 2010-12-03 the code hasn't been touched since 2004.
;;
;;  Details of the info file fields
;;
;;     Bugs
;;
;;      URL where the bugs should be reported. This can be email address
;;      or link to a issue tracker of upstream project. Note: send
;;      problems epackage problems to address mentioned in `Maintainer'.
;;
;;    Compat
;;
;;      The compatibility level this epackage. The Epackage format may
;;      change in time and this field indicates for which version the
;;      software was packaged. If the value is missing or is empty, no
;;      specific compatibility version is required and latest is assumed.
;;      Usually all epackage maintainers should update their work to the
;;      latest format to prevent installation problems. See section
;;      "Epackage Comatibility Levels" for more information.
;;
;;     Conflicts
;;
;;      This field lists packages that must be removed before install
;;      should be done. This field follow guidelines of
;;      <http://www.debian.org/doc/debian-policy/ch-relationships.html>.
;;
;;     Depends (required)
;;
;;      List of dependencies: Emacs flavor and packages required. The
;;      version information is enclosed in parentheses with comparison
;;      operators ">=" and "<=". A between range is not defined. This
;;      field follow guidelines of
;;      <http://www.debian.org/doc/debian-policy/ch-relationships.html>.
;;
;;      In case program works inly in certain Emacs versions, this
;;      information should be announces in field "Status::note" (which
;;      see). Packages that are not updated to work for latest Emacs
;;      versions are candidate for removal from package archive
;;      anyway. An example:
;;
;;              Depends: emacs (>= 22.2.2) | xemacs (>= 20)
;;
;;     Description (required)
;;
;;      The first line of this field is a consise description that fits on
;;      maximum line length of 80 characters in order to display in
;;      combined format "PACKAGE -- SHORT DESCRIPTION". The longer
;;      description is explained in paragraphs that are separated from
;;      each orher with a single (.) at its own line. The paragraphs
;;      are recommended to be intended by one space.
;;
;;     Email
;;
;;      Upstream developers email address(es). Multiple developers
;;      are listed like in email: separated by commas. Teh role can
;;      be expressed in parenthesis. An example:
;;
;;              Email: John doe (Author) <jdoe@example.com>,
;;               Joe Average (Co-developer) <jave@example.com>
;;
;;     Homepage
;;
;;      URL to the project homepage. For this field it is adviseable to use
;;      project a addresses that doesn't move; those of Freshmeat.net,
;;      Sourceforge, Launchpad, Github etc. The Freshmeat is especially
;;      good because it provides an easy hub to all other related Open
;;      Source projects. Through Freshmeat users can quickly browse related
;;      software and subscribe to project announcements. Freshmeat is also
;;      easy for the upstream developer to set up because it requires no
;;      heavy project management (it's kind of "yellow pages").
;;
;;      In any case, the Homepage link should not directly point to a
;;      volatile personal homepage if an alternative exists. Try to
;;      encourage "Garage" upstream developers to set up their software at
;;      some project hosting site that would contain an issue tracker.
;;      Examples: Sourceforge.net, Savannah.gnu.org, Bitbucket.com,
;;      Github.com, Gitorious.com etc. For more information, see
;;      <http://en.wikipedia.org/wiki/Comparison_of_open_source_software_hosting_facilities>.
;;
;;     License
;;
;;      If misssing, the value is automatically assumed "GPL-2+". The valid
;;      License abbreviations should follow list defined at
;;      <http://wiki.debian.org/CopyrightFormat>. A special word "None"
;;      should be used if the software has no license information in any of
;;      the source files.
;;
;;     Maintainer
;;
;;      The packaged who maintains the utility in epackage format. If
;;      this field is missing `Email' is assumed. Best if upstream (Email)
;;      is also the Maintainer of epackage.
;;
;;     Package (required)
;;
;;      The name of the PACKAGE in all lowercase, satisfying regexp
;;      "[a-z0-9-]+". Usually basename of the file name like
;;      package.el or the canonical known name in case of bigger
;;      packages like "gnus". An example "html-helper-mode.el" =>
;;      package name is "html-helper-mode". It is adviseable to always
;;      add *-mode even if file does not explicitly say so. An example
;;      "python.el" => package name is "python-mode". No two packages
;;      can have same name. Please contact package author in case of
;;      name clashes.
;;
;;     Recommends
;;
;;      This field lists additional packages that the current package
;;      can utilize. E.g a package A, can take advantage of package B,
;;      if it is aailable, but it is not a requirement to install B
;;      for package A to work. This field is *not* used to annouce
;;      related packages. That information can be mentioned in
;;      the end of "Description" in paragraph "SEE ALSO".
;;
;;     Section (required)
;;
;;      This field contains category for package. The valid keywords are
;;      those listed in `M-x' `finder-list-keywords'.
;;
;;     Status
;;
;;      This field lists information about the package. Each keyword
;;      has a unique mening. the allowed list:
;;
;;          keyword := core-emacs
;;                     | core-xemacs
;;                     | unmaintained
;;                     | broken
;;                     | unsafe
;;                     | stable
;;                     | unstable
;;                     | experimental
;;
;;      The `core-*' values mark the package being included (or will be) in
;;      the latest [X]Emacs. Value `unmaintained' means that the original
;;      developer has vanished or abandoned the project and is no longer
;;      available for developing the package. Value `unsafe' means that the
;;      not all the symmbols are name space clean (prefix-*), so some of
;;      the commands might clash with existing ones. The current release
;;      status of package can be indicated with term `stable' (no more
;;      actively developed, bugs shaken out), `unstable' (package is in
;;      active development) and `experimental' (no gurantees, not
;;      necessarily tested but this is the latest code). Value `broken'
;;      means that package is broken and does not work in some Emacs
;;      version (usually latest).
;;
;;     Vcs-Browser
;;
;;      The URL address to the version control browser of the repository.
;;
;;     Vcs-Type
;;
;;      Version Control System type information. The value is the
;;      lowercase name of the version control program; cvs, svn, bzr, hg,
;;      git etc. A special value "http" can be used to signify direct HTTP
;;      download. An example of an Emacs package hosted directly at a web
;;      page:
;;
;;          Vcs-Type: http
;;          Vcs-Url: http://www.emacswiki.org/emacs/download/vline.el
;;
;;     Vcs-Url
;;
;;      The Version Control System repository URL without any options. For
;;      CVS, this is the value of CVSROOT which includes also the protocol
;;      name:
;;
;;          Vcs-Type: cvs
;;          Vcs-Url: :pserver:anonymous@example.com/reository/foo
;;
;;     Vcs-Args
;;
;;      Additional arguments passed to VCS program after speficying the *Vcs-Url*
;;      E.g. CVS directories may need a specific module to check out. A setup like
;;      below would yield command: "cvs -d <Vcs-Url> co -d <Package> <Vcs-Args>"
;;
;;          Vcs-Type: cvs
;;          Vcs-Url: :pserver:anonymous@example.com/reository/foo
;;          Vcs-Args: module
;;
;;     Vcs-User
;;
;;      The Version Control System repository's login name. In case the
;;      repository cannot be accessed simply by visiting the `Vcs-Url' (or
;;      in the case of CVS: pressing RETURN at login prompt), this is the
;;      login name.
;;
;;     Vcs-Password
;;
;;      The Version Control System repository's password. In some rara cases
;;      a generic password, like "anonymous" to access repository is needed.
;;
;;     Wiki
;;
;;      This field points to package at <http://www.emacswiki.org>. If
;;      it does not exists, consider creating one for the PACKAGE.
;;
;;     X-*
;;
;;      Any other custom fields can be inserted using `X-*' field
;;      notation:
;;
;;          X-Comment: <comment here>
;;          X-Upstream-Homepage: <URL>
;;
;; Epackage Compatibility Levels
;;
;;   The latest epackage format is alwyas described in section "Epackage
;;   specification" above. In here you find list of older format and
;;   changes since (Currently none). This section interests epackage
;;   maintainers that update their packaging.
;;
;;   o  2010-12-03 Compatibility level 1 specification written.
;;
;; TODO
;;
;;      - GUI: After download. Trying to install or arctivate package,
;;        check emacs compatibility and refuse to install if not met.
;:
;;      - Verify Compatibility Level of downloaded epackage
;;      - Run health check for downloaded Epackage
;;
;;      - Verify sources list file: No duplicate same packages.
;;
;;      - What to do if Yellow pages URL (repo) chnages and you have the old one
;;        installed? How to cope with the change? The Git repository may
;;        need to be destroyed and downloaded again to be sure (not
;;        necessarily derived from old one).
;;
;;      - What if epackage maintainer kills the repo and reinstantiates it
;;        from fresh? Symptoms: can't pull, because repos have diverged and
;;        do not have common objects. SOLUTION: offer deleting repo and
;;        downloading it again. Warn if there are any local modifications,
;;        the user might want ot have a backup (*.b). Can we do that? What
;;        if a backup already exists?
;;
;;      - Move package list into Git repository
;;      - GUI: drop outline. If user selects DETAIL view, collect
;;        information to another buffer dynamically (info, git tags,
;;        current git branch)
;;
;;      - New file: cache. Build it dynamically from packages and
;;        combine with package information (e.g. version).
;;
;;      - Use 00link directory where to draw symlinks. This is faster
;;        than using many paths in `load-path' but it won't work in
;;        Windows.
;;        => make it configurable
;;      - Dynamically search all *.el and *elc. When byte compiled,
;;        symlink those files as well.
;;
;;      - Install action by default runs eable (*-autoloads),
;;        unless user has activated auto-activate feature (toggle)
;;      - Another toggle is auto-byte-compile feature on package install.
;;
;;      - refetch repository (destroy, re-download).
;;
;;      - Git tags, where is this information kept?
;;      - How to update package, or all packages?
;;        => Running git preocess? When update is avilable how to flag this?
;;        => What about conflits?
;;      - What about 'local', manual branch and updates?
;;      - Retrieve new yellow pages (available packages)
;;      - Rescan current information? (what is installed, what is not)
;;        => Keep cache? Or regenerate, or scan at startup every time?
;;      - What if user manually deletes directories? Refresh?
;;      - Package health check, Lint?
;;      - Edit yellow pages catalog?
;;        => Submit/update yellow pages catalog changes?
;;        => version controlled, patches? Interface to automatic email?
;;      - Yellow pages URL health check? What to do with broken links?

;;; Change Log:

;;; Code:

(defconst epackage-version-time "2010.1204.1549"
  "*Version of last edit.")

(defcustom epackage--load-hook nil
  "*Hook run when file has been loaded."
  :type  'hook
  :group 'Epackage)

(defcustom epackage--byte-compile-loader-file nil
  "*Non-nil measn to byte compile `epackage--loader-file'."
  :type  'boolean
  :group 'Epackage)

(defcustom epackage--sources-list-url
  "jaalto@cante.net:srv/git/emacs-lisp-dev--epackage-sources-list"
  "URL to the location of available package list. The yellow pages.
This is the Git repository that contains the canonical list of
available packages.

The included text file contains information about package names
and their repository download URLs. Empty lines and comment on
their own lines started with character '#' are ignored:

  # Comment
  PACKAGE-NAME REPOSITORY-URL DESCRIPTION
  PACKAGE-NAME REPOSITORY-URL DESCRIPTION
  ...

An example:

  foo git://example.com/repository/foo.git")

(defconst epackage--sources-package-name "00epackage"
  "The name of local repository of `epackage--sources-list-url'.")

(defcustom epackage--root-directory
  (let (ret)
    (dolist (elt (list
                  (if (featurep 'xemacs)
                      "~/.xemacs.d"
                    "~/.emacs.d")
                  "~/elisp"))
      (if (and elt
               (null ret)
               (file-directory-p elt))
          (setq ret elt)))
    (cond
     (ret
      ret)
     (t
      ;; No known package installation root directory
      (message
       (concat "Epackage: [ERROR] Can't determine location of lisp packages."
               "Please define `epackage--root-directory'.")))))
  "*Location of lisp files. Typically ~/.emacs.d or ~/elisp.
Directory should not contain a trailing slash."
  :type  'directory
  :group 'Epackage)

(defvar epackage--directory-name "epackage"
  "Name of package directory under `epackage--root-directory'.
Use function `epackage-directory' for full path name.")

(defvar epackage--directory-name-vcs "packages"
  "VCS directory under `epackage--root-directory'.
Use function `epackage-file-name-vcs-compose' for full path name.")

(defvar epackage--directory-name-install "install"
  "Install directory under `epackage--root-directory'.")

(defvar epackage--directory-name-link "00link"
  "Link directory under `epackage--root-directory'.
This directory contains symlinks to all installed packages and
their *.el and *.elc files.")

(defconst epackage--directory-exclude-regexp
  (concat
   "/\\.\\.?$"
   "\\|/RCS$"
   "\\|/rcs$"
   "\\|/CVS$"
   "\\|/cvs$"
   "\\|/\\.\\(svn\\|git\\|bzr\\|hg\\|mtn\\|darcs\\)$"
   "\\|/"
   epackage--directory-name
   "$")
  "Regexp to exclude dirctory names.")

(defconst epackage--layout-mapping
  '((activate . "xactivate")
    (autoload . "autoloads")
    (enable . "install")
    (info . "info")
    (loaddefs . "loaddefs")
    (uninstall . "uninstall"))
  "File name mappings under epackage/ directory.
Format is:
  '((TYPE . FILENAME) ...)

Used in `epackage-file-name-vcs-directory-control-file'.")

(defvar epackage--initialize-flag nil
  "Set to t, when epackage has been started. do not touch.")

(defvar epackage--program-git nil
  "Location of program git(1).")

(defvar epackage--sources-file-name "epackage.lst"
  "Name of yellow pages file that lists available packages.
See variable `epackage--sources-list-url'.")

(defvar epackage--loader-file "epackage-loader.el"
  "file that contains all package enable and activate code.
See `epackage-loader-file-generate'.")

(defvar epackage--package-control-directory "epackage"
  "Name of directory inside VCS controlled package.")

(defvar epackage--process-output "*Epackage process*"
  "Output of `epackage--program-git'.")

(defvar epackage--debug t
  "If non-nil, activate debug.")

(defsubst epackage-file-name-compose (name)
  "Return path to NAME in epackage directory."
  (format "%s/%s"
          (epackage-directory)
          name))

(defsubst epackage-file-name-loader-file ()
  "Return path to boot loader file."
  (format "%s/%s"
          (epackage-directory)
          epackage--loader-file))

(defsubst epackage-file-name-vcs-compose (package)
  "Return VCS directory for PACKAGE."
  (format "%s/%s%s"
          (epackage-directory)
          epackage--directory-name-vcs
          (if (string= "" package)
              ""
            (concat "/" package))))

(defsubst epackage-file-name-vcs-directory ()
  "Return VCS directory"
  (epackage-file-name-vcs-compose ""))

(defsubst epackage-file-name-install-directory ()
  "Return VCS directory"
  (format "%s/%s"
          (epackage-directory)
          epackage--directory-name-install))

(defsubst epackage-file-name-link-directory ()
  "Return link directory"
  (format "%s/%s"
          (epackage-directory)
          epackage--directory-name-link))

(defsubst epackage-file-name-vcs-package-control-directory (package)
  "Return control directory of PACKAGE"
  (let ((root (epackage-file-name-vcs-compose package)))
    (format "%s/%s" root epackage--package-control-directory)))

(defun epackage-file-name-vcs-directory-control-file (package type)
  "Return PACKAGE's control file of TYPE.

TYPE can be on of the following:

  'activate
  'autoload
  'enable
  'info
  'loaddefs
  'uninstall

Refer top Epackage specification for more information in
documentation of epackage.el."
  (let ((dir (epackage-file-name-vcs-package-control-directory package))
        (file (cdr-safe (assq type epackage--layout-mapping))))
    (if (not file)
        (error "Epackage: [ERROR] Unknown TYPE argument '%s'" type)
      (cond
       ((eq type 'info)
         (format "%s/%s" dir file))
       (t
        (format "%s/%s-%s.el" dir package file))))))

(defsubst epackage-file-name-activated-compose (package)
  "Return path to PACKAGE under activated directory."
  (format "%s/%s%s"
          (epackage-directory)
          epackage--directory-name-install
          (if (string= "" package)
              ""
            (format "/%s-xactivate.el" package))))

(defsubst epackage-file-name-enabled-compose (package)
  "Return path to PACKAGE under install directory."
  (format "%s/%s%s"
          (epackage-directory)
          epackage--directory-name-install
          (if (string= "" package)
              ""
            (format "/%s-install.el" package))))

(defun epackage-package-enabled-p (package)
  "Return file if PACKAGE is enabled."
  (let ((file (epackage-file-name-enabled-compose package)))
    (if (file-exists-p file)
        file)))

(defun epackage-package-activated-p (package)
  "Return file if PACKAGE is activated."
  (let ((file (epackage-file-name-activated-compose package)))
    (if (file-exists-p file)
        file)))

(defun epackage-package-downloaded-p (package)
  "Check if package has been downloaded."
  (unless (stringp package)
    (error "Epackage: [ERROR arg 'package' is not a string."))
  (let ((dir (epackage-file-name-vcs-compose package)))
    (file-directory-p dir)))

(defun epackage-package-activated-p (package)
  "Check if package has been activated, return activate file."
  (unless (stringp package)
    (error "Epackage: [ERROR] arg 'package' is not a string."))
  (let ((file (epackage-file-name-activated-compose package)))
    (if (file-exists-p file)
        file)))

(defun epackage-package-enabled-p (package)
  "Check if package has been enabled, return enabled file."
  (unless (stringp package)
    (error "Epackage: [ERROR] arg 'package' is not a string."))
  (let ((file (epackage-file-name-install-compose package)))
    (if (file-exists-p file)
        file)))

(defsubst epackage-sources-list-directory ()
  "Return sources list, the yellow pages, directory."
  (epackage-file-name-vcs-compose epackage--sources-package-name))

(defsubst epackage-file-name-sources-list ()
  "Return path to `epackage--sources-file-name'."
  (format "%s/%s"
          (epackage-sources-list-directory)
          epackage--sources-file-name))

(defsubst epackage-sources-list-p ()
  "Check existence of `epackage--sources-file-name'."
  (file-exists-p (epackage-file-name-sources-list)))

(defsubst epackage-sources-list-verify ()
  "Signal error if `epackage--sources-file-name' does not exist."
  (unless (epackage-sources-list-p)
    (error "Epackage: Missing file %s. Run epackage-initialize"
           (epackage-file-name-sources-list))))

(defun epackage-program-git-verify ()
  "Verify variable `epackage--program-git'."
  (when (or (not (stringp epackage--program-git))
            (not (file-exists-p epackage--program-git)))
    (error
     (substitute-command-keys
      (format
       `,(concat
          "Epackage: [ERROR] Invalid value in `epackage--program-git' (%s) "
          "Run \\[epackage-initialize]")
          epackage--program-git)))))

(defun epackage-directory ()
  "Return root directory."
  (format "%s%s"
          (expand-file-name
           (file-name-as-directory epackage--root-directory))
          (if (stringp epackage--directory-name)
              epackage--directory-name
            (error
             "Epackage: [ERROR] epackage--directory-name is not a string"))))

(put 'epackage-with-debug 'lisp-indent-function 0)
(put 'epackage-with-debug 'edebug-form-spec '(body))
(defmacro epackage-with-debug (&rest body)
  "Run BODY if variable `epackage--debug' is non-nil."
  `(when epackage--debug
     ,@body))

(put 'epackage-with-directory 'lisp-indent-function 1)
(put 'epackage-with-directory 'edebug-form-spec '(body))
(defmacro epackage-with-directory (dir &rest body)
  "Set `default-directory' to DIR while running BODY."
  `(let ((default-directory (file-name-as-directory ,dir))) ;Must end in slash
     ,@body))

(put 'epackage-with-binary 'lisp-indent-function 0)
(put 'epackage-with-binary 'edebug-form-spec '(body))
(defmacro epackage-with-binary (&rest body)
  "Disable all interfering `write-file' effects and run BODY."
  `(let ((version-control 'never)
         (backup-inhibited t)
         (buffer-file-coding-system 'no-conversion)
         write-file-functions
         after-save-hook)
     ,@body))

(put 'epackage-with-sources-list 'lisp-indent-function 0)
(put 'epackage-with-sources-list 'edebug-form-spec '(body))
(defmacro epackage-with-sources-list (&rest body)
  "Run BODY in package list buffer."
  `(progn
     (epackage-sources-list-verify)
     (with-current-buffer
         (find-file-noselect (epackage-file-name-sources-list))
       ,@body)))

(defsubst epackage-git-error-handler (&optional command)
  "On Git error, show proces buffer and signal error."
  (display-buffer epackage--process-output)
  (error "Epackage: [ERROR] Git %scommand error"
         (if command
             (format "'%s' " command)
           "")))

(put 'epackage-with-process-output 'lisp-indent-function 0)
(put 'epackage-with-process-output 'edebug-form-spec '(body))
(defmacro epackage-with-process-output (&rest body)
  "Run BODY in `epackage--process-output'."
  `(with-current-buffer (get-buffer-create epackage--process-output)
     ,@body))

(defsubst epackage-git-goto-last-output-start ()
  "Move to last marker --CMD START-- and the following line.
Used inside `epackage-with-process-output'."
  (goto-char (point-max))
  (re-search-backward "--CMD START--")
  (forward-line 1))

(put 'epackage-with-last-git-output 'lisp-indent-function 0)
(put 'epackage-with-last-git-output 'edebug-form-spec '(body))
(defmacro epackage-with-last-git-output (&rest body)
  "Run BODY at start of last git output."
  `(epackage-with-process-output
     (epackage-git-goto-last-output-start)
     ,@body))

(defsubst epackage-git-command-ok-p (status)
  "Return non-nil if command STATUS was ok."
  (zerop status))

(defun epackage-git-command-process (&rest args)
  "Run git COMMAND with output to `epackage--process-output'."
  (epackage-program-git-verify)
  (epackage-with-debug
    (let ((dir default-directory)) ;; buffer local variable
      (epackage-with-process-output
        (goto-char (point-max))
        (insert
         (format ">> debug: [%s] git %s\n"
                 dir
                 (prin1-to-string args))))))
  (epackage-with-process-output
    (goto-char (point-max))
    (insert "--CMD START--\n"))
  (apply 'call-process
         epackage--program-git
         (not 'infile)
         (get-buffer-create epackage--process-output)
         (not 'display)
         args))

(put 'epackage-with-git-command 'lisp-indent-function 2)
(put 'epackage-with-git-command 'edebug-form-spec '(body))
(defmacro epackage-with-git-command (dir verbose &rest args)
  "Run git command in DIR with ARGS.
If VERBOSE is non-nil, display progress message."
  `(epackage-with-directory ,dir
     (if verbose
         (message "Epackage: Running 'git %s' in %s ..."
                  (apply 'mapconcat ,args " ")
                  ,dir))
     (prog1
         (unless (epackage-git-command-ok-p
                  (epackage-git-command-process
                   ,@args))
           (epackage-git-error-handler "pull")))
     (if verbose
         (message "Epackage: Running 'git %s' in %s ...done"
                  (apply 'mapconcat ,args " ")
                  ,dir))))

(defsubst epackage-git-branch-list-master-p (list)
  "Return non-nil if current branch LIST indicates master as current branch."
  (string-match
   ;; At the beginning, or at end, or in the middle by spaces
   "\\(?:^\\| \\)\\*master\\(?: \\|$\\)"
   (mapconcat 'concat list " ")))

(defun epackage-git-command-tag-list (dir &optional verbose)
  "Run 'git branch' in DIR.
If VERBOSE is non-nil, display progress message.

Return:
    List of branches. The current branch has mark '*' at front."
  (epackage-with-git-command dir verbose
    "branch")
  (epackage-with-last-git-output
    (let (list)
      (while (re-search-forward "^\\([^ \t\r\n]*+\\)" nil t)
        (setq list (cons
                    (match-string-no-properties 1)
                    list)))
      list)))

(defun epackage-git-command-tag-list (dir &optional verbose)
  "Run 'git tag -l' in DIR.
If VERBOSE is non-nil, display progress message.

Return:
    List of tag names."
  (epackage-with-git-command dir verbose
    "tag" "-l")
  (epackage-with-last-git-output
    (let (list)
      (while (re-search-forward "^\\(\\*?\\) +\\([^ \t\r\n]*\\)" nil t)
        (setq list (cons
                    (concat
                     (match-string-no-properties 1)
                     (match-string-no-properties 2))
                    list)))
      list)))

(defun epackage-git-branch-list-current-branch (list)
  "Return name makred with '*' from branch LIST; without the '*'."
  (let (ret)
    (dolist (elt list)
      (when (and (not  ret)
                 (string-match "^\\*\\(.+\\)" elt))
        (setq ret (match-string-no-properties 1 elt))))
    ret))

(defsubst epackage-git-command-branch-current-name (dir &optional verbose)
  "Run 'git branch' in DIR and return active branch name.
If VERBOSE is non-nil, display progress message."
  (epackage-git-branch-list-current-branch
   (epackage-git-command-branch-list dir verbose)))

(defun epackage-git-command-pull (dir &optional verbose)
  "Run 'git branch' in DIR.
If VERBOSE is non-nil, display progress message."
  (epackage-with-git-command dir verbose
    "pull"))

(defun epackage-git-command-clone (url dir &optional verbose)
  "Run 'git clone URL DIR' in VCS package directory vault.
If VERBOSE is non-nil, display progress message."
  (epackage-with-directory (epackage-file-name-vcs-directory)
    (epackage-with-git-command dir verbose
      "clone" url dir)))

(defun epackage-master-p (package)
  "Return non-nil if PACKAGE's VCS branch is master."
  (let ((dir (epackage-file-name-vcs-compose package)))
    (when (file-directory-p dir)
      (let ((list (epackage-git-command-branch-list dir)))
        (epackage-git-branch-list-master-p list)))))

(defun epackage-upgrade-package (package &optional verbose)
  "Upgrade PACKAGE in VCS directory.
If VERBOSE is non-nil, display progress message."
  (let ((url (epackage-sources-list-info-url package)))
    (unless url
      (error "Epackage: [ERROR] No Git URL for package '%s'" package))
    (let ((dir (epackage-file-name-vcs-compose package)))
      (if verbose
          (message "Upgrading package: %s..." package))
      (unless (epackage-master-p package)
        (error
         `,(concat
            "Epackage: [FATAL] Can't upgrade. "
            "Branch name is not 'master' in '%'. "
            "Possibly changed manually or invalid package.")
         dir)
        (epackage-git-command-pull dir)
      (if verbose
          (message "Upgrading package: %s...done" package))))))

(defun epackage-upgrade-sources-list ()
  "Update list of available packages; the yellow pages."
  (let ((dir (epackage-sources-list-directory)))
    (unless (file-directory-p dir)
      (error
       (substitute-command-keys
        (format
         (concat "Epackage: No such directory '%s'. "
                 "Run \\[epackage-initialize]")
         dir))))
    (epackage-git-command-pull dir)))

(defun epackage-download-package (package &optional verbose)
  "Download PACKAGE to VCS directory.
If VERBOSE is non-nil, display progress message."
  (let ((url (epackage-sources-list-info-url package)))
    (unless url
      (error "Epackage: [ERROR] No Git URL for package '%s'" package))
    (let ((dir (epackage-file-name-vcs-compose package)))
      (epackage-git-command-clone url dir))))

(defun epackage-enable-package (package)
  "Enable PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
               package 'enable))
        (to (epackage-file-name-install-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: [ERROR] File does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-activate-package (package)
  "Activate PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
               package 'activate))
        (to (epackage-file-name-activated-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: [ERROR] file does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-enable-package (package)
  "Activate PACKAGE."
  (let ((from (epackage-file-name-vcs-directory-control-file
               package 'enable))
        (to (epackage-file-name-enabled-compose package)))
    (unless (file-exists-p from)
      (error "Epackage: [ERROR] file does not exists: %s" from))
    (copy-file from to 'overwrite 'keep-time)))

(defun epackage-disable-package (package)
  "Disable PACKAGE."
  (dolist (file (directory-files
                 (epackage-file-name-install-directory)
                 'full-path
                 (format "^%s-.*\\.el" package)
                 t))
    (if (file-exists-p file)
        (delete-file file))))

(defun epackage-action-package (package action)
  "Perform ACTION on PACKAGE.

ACTION can be:

  'enable
  'disable
  'activate
  'uninstall"
  ;; FIXME: Not implemented
  )

(defun epackage-directory-list (dir)
  "Return all directories under DIR."
  (let (list)
    (dolist (elt (directory-files dir 'full))
      (when (and (file-directory-p elt)
                 (not (string-match
                       epackage--directory-exclude-regexp
                       elt)))
        (setq list (cons elt list))))
    list))

(defun epackage-directory-recursive-list (dir list)
  "Return all directories under DIR recursively to LIST.
Exclude directories than contain file .nosearch
or whose name match `epackage--directory-name'."
  (let ((dirs (epackage-directory-list dir)))
    (setq list (cons dir list))
    (dolist (elt dirs)
      (cond
       ((file-exists-p (concat elt "/.nosearch")))
       (t
        (setq list (cons elt list))
        (epackage-directory-recursive-list elt list))))
    list))

(defun epackage-loader-file-insert-header ()
  "Insert header comments."
  (insert
   (format
    "\
;; Epackge boot file -- automatically generated
;;
;; Do not modify. Changes done here will be lost.
;; Add following to your ~/.emacs to use this file:
;;   (load-file \"%s\")

"
    (file-name-sans-extension
     (epackage-file-name-loader-file)))))

(defsubst epackage-loader-file-insert-footer ()
  "Insert Footer."
  (insert
   (format "\
\(provide '%s)

;; End of file
"
           (file-name-sans-extension
            (file-name-nondirectory
             (epackage-file-name-loader-file))))))

(defun epackage-loader-insert-file-path-list-by-path (path)
  "Insert `load-path' definitions to `current-buffer' from PATH."
  (let (list)
    (dolist (dir (epackage-directory-recursive-list path list))
      (insert (format
               "(add-to-list 'load-path \"%s\")\n"
               dir)))))

(defun epackage-loader-file-insert-path-list ()
  "Insert `load-path' commands to `current-buffer'."
  (let (name
        package
        list)
    (dolist (file (directory-files
                   (epackage-file-name-install-directory)
                   'full-path
                   "^.*-.*\\.el"
                   t))
      (setq name
            (file-name-sans-extension
             (file-name-nondirectory file)))
      ;; package-name-autoloads => package-name
      (setq package (replace-regexp-in-string  "-[^-]+$" "" name))
      (unless (member package list)
        (add-to-list 'list package)
        (epackage-loader-insert-file-path-list-by-path
          (epackage-file-name-vcs-compose package))))))

(defun epackage-loader-file-insert-install-code ()
  "Insert package installation code into `current-buffer'."
  ;; FIXME: Should only insert activate, not enable code if both exist
  (dolist (file (directory-files
                 (epackage-file-name-install-directory)
                 'full-path
                 "^.*-.*\\.el"
                 t))
    (goto-char (point-max))
    (insert-file-contents-literally file)))

(defsubst epackage-loader-file-insert-main ()
  "Insert Epackage loader boot commands to current point."
  (epackage-loader-file-insert-header)
  (epackage-loader-file-insert-path-list)
  (epackage-loader-file-insert-install-code)
  (epackage-loader-file-insert-footer))

(defun epackage-loader-file-byte-compile ()
  "Byte compile `epackage-file-name-loader-file'."
  (interactive)
  (let ((file (epackage-file-name-loader-file)))
    (if (file-exists-p file)
        (byte-compile-file file))))

(defsubst epackage-loader-file-byte-compile-maybe ()
  "Check `epackage--byte-compile-loader-file' and byte compile."
  (when epackage--byte-compile-loader-file
    (epackage-loader-file-byte-compile)))

(defun epackage-loader-file-generate ()
  "Generate main loader for all installed or activated packages."
  (interactive)
  (let ((file (epackage-file-name-loader-file)))
    (with-current-buffer (find-file-noselect file)
      (delete-region (point-min) (point-max))
      (epackage-loader-file-insert-main)
      (write-region (point-min)
                    (point-max)
                    (epackage-file-name-loader-file))
      (set-buffer-modified-p nil)
      (kill-buffer (current-buffer))
      (epackage-loader-file-byte-compile-maybe))))

(defun epackage-sources-list-info-main (package)
  "Return '(pkg url description) for PACKAGE.
Format is described in variable `epackage--sources-list-url'."
  (epackage-with-sources-list
   (goto-char (point-min))
   (let ((re
          (format
           `,(concat "^\\(%s\\)\\>"
                     "[ \t]+\\([^ \t\r\n]+\\)"
                     "[ \t]*\\([^ \t\r\n]*\\)")
           (regexp-quote package))))
     (when (re-search-forward re nil t)
       (list
        (match-string-no-properties 1)
        (match-string-no-properties 2)
        (match-string-no-properties 3))))))

(defun epackage-sources-list-info-url (package)
  "Return URL for PACKAGE."
  (let ((info (epackage-sources-list-info-main package)))
    (when info
      (nth 1 info))))

(defun epackage-require-emacs ()
  "Require Emacs features."
  (unless (fboundp 'url-retrieve-synchronously)
    (error (concat
            "Epackage: [ERROR] this Emacs does not define "
            "`url-retrieve-synchronously' from url.el"))))

(defun epackage-require-git ()
  "Require Git program."
  (cond
   ((null epackage--program-git)
    (let ((bin (executable-find "git")))
      (unless bin
        (error "Epackage: [ERROR] program 'git' not found in PATH"))
      (setq epackage--program-git bin)))
   ((and (stringp epackage--program-git)
         (not (file-exists-p epackage--program-git)))
    (error "Epackage: [ERROR] Invalid `epackage--program-git' (%s)"
           epackage--program-git))
   ((file-executable-p epackage--program-git)) ;All ok
   (t
    (error "Epackage: [ERROR] Unknown value in `epackage--program-git' (%s)"
           epackage--program-git))))

(defun epackage-require-directories ()
  "Buid directory structure."
  (dolist (dir (list
                (epackage-directory)
                (epackage-file-name-vcs-directory)
                (epackage-file-name-install-directory)
                (epackage-file-name-link-directory)))
    (unless (file-directory-p dir)
      (message "Epackage: Making directory %s ..." dir)
      (make-directory dir))))

(defun epackage-require-main ()
  "Check requirements to run Epackage."
  (epackage-require-emacs)
  (epackage-require-git)
  (epackage-require-directories))

(defun epackage-url-http-parse-respons-error (&optional url)
  "On HTTP GET error, show reponse and signal error for optional URL."
  (let ((status (url-http-parse-response)))
    (when (or (< status 200)
              (>= status 300))
      (display-buffer (current-buffer))
      (error "[ERROR] HTTP access problem %d%s"
             status
             (if url
                 (concat " " url)
               "")))))

(defun epackage-url-retrieve-main (url file)
  "Download URL and save to a FILE."
  (let ((buffer (url-retrieve-synchronously url)))
    (unless buffer
      (error "Epackage: [ERROR] can't access url: %s" url))
    (with-current-buffer buffer
      (epackage-url-http-parse-respons-error url)
      (re-search-forward "^$" nil 'move)
      (forward-char)
      (epackage-with-binary
        (write-region (point) (point-max) file)
        (kill-buffer (current-buffer))))))

(defun epackage-download-sources-list (&optional message)
  "Download sources list file, the yellow pages."
  (if message
      (message message))
  (if (epackage-sources-list-p)
      (error "Epackage: [ERROR] Directory already exists: %s"
             (epackage-sources-list-directory)))
  (epackage-git-command-clone epackage--sources-list-url dir))

(defun epackage-cmd-download-sources-list ()
  "Download or upgrade package list; the yellow pages of package repositories."
  (interactive)
  (if (epackage-sources-list-p)
      (epackage-upgrade-sources-list "Upgrading available package list")
    (epackage-download-sources-list "Downloading available package list")))

(defun epackage-cmd-download-package (PACKAGE)
  "Download PACKAGE, but do not install it."
  (if (not (epackage-sources-list-p))
      (message
       (substitute-command-keys
        "Epackage: No package list. Run \\[epackage-cmd-download-sources-list]"))
    (let ()
      ;; FIXME: Present list of package as completing-read
      )))

(defun epackage-initialize ()
  "Inialize package."
  (unless epackage--initialize-flag
    (epackage-require-main))
  (unless (epackage-sources-list-p)
    (epackage-cmd-download-sources-list))
  (setq epackage--initialize-flag t))

;;;###autoload (autoload 'epackage-mode          "epackage" "" t)
;;;###autoload (autoload 'turn-on-epackage-mode  "epackage" "" t)
;;;###autoload (autoload 'tun-off-epackage-mode  "epackage" "" t)
;;;###autoload (autoload 'epackage-commentary    "epackage" "" t)

;; FIXME: Unfinished, this is at a sketch / planning phase.

;; (eval-and-compile
;;   (ti::macrof-minor-mode-wizard
;;    "epackage-" " Epkg" "z" "Epkg" 'Epackage "epackage--"
;;    "Emacs package manager

;; Mode description:

;; \\{epackage--mode-prefix-map}"

;;    "Epackage"
;;    nil
;;    "Number conversion mode"
;;    (list                                ;arg 10
;;     epackage--mode-easymenu-name
;;     "----"
;;     ["Package version"    epackage-version        t]
;;     ["Package commentary" epackage-commentary     t]
;;     ["Mode help"   epackage-mode-help   t]
;;     ["Mode off"    epackage-mode        t])
;;    (progn
;;      (define-key map "v"  'epackage-version)
;;      (define-key map "?"  'epackage-mode-help)
;;      (define-key map "Hm" 'epackage-mode-help)
;;      (define-key map "Hc" 'epackage-commentary)
;;      (define-key map "Hv" 'epackage-version))))

(defsubst epackage-directory-name ()
  "Return package directory.
Refences:
  `epackage--package-root-directory'
  `epackage--directory-name'."
  (if (and (stringp epackage--root-directory)
           (stringp epackage--directory-name))
      (format "%s/%s"
              epackage--root-directory
              epackage--directory-name)
    (error (concat "Epackge: [FATAL] Invalid epackage--root-directory"
                    " or epackage--directory-name"))))

(add-hook  'epackage--mode-hook 'epackage-mode-define-keys)
(provide   'epackage)
(run-hooks 'epackage--load-hook)

;;; epackage.el ends here