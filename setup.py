import setuptools

import sys
print sys.path

setuptools.setup(
    name="git-remote-hg",
    version='1.0.0',
    author="Mark Nauwelaerts",
    author_email="mnauw@users.sourceforge.net",
    url="http://github.com/mnauw/git-remote-hg",
    description="access hg repositories as git remotes",
    long_description="""
                 'git-remote-hg' is a git-remote protocol helper for Mercurial.
                 It allows you to clone, fetch and push to and from Mercurial repositories as if
                 they were Git ones using a hg::some-url URL.
                 
                 See the homepage for much more explanation.
                 """,
    license="GPLv2",
    keywords="git hg mercurial",
    packages=[
        'git_remote_hg',
    ],
    scripts=[
        'git-remote-hg',
        'git-hg-helper',
    ],
    classifiers=[
        "Programming Language :: Python",
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 2.7",
        "License :: OSI Approved",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
    ],
    zip_safe=False,
)
