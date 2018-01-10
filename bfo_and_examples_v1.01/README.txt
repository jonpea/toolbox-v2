%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                           %
%                                       README                                              %
%                                                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                                                   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%        BFO, A Brute Force Optimizer               %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%        version 1.01                               %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%        (c) 2016, Ph. Toint and M. Porcelli        %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%                                                   %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   REFERENCES: M. Porcelli and Ph. L. Toint,
%               "BFO, a trainable derivative-free Brute Force Optimizer for 
%               nonlinear bound-constrained optimization and equilibrium 
%               computations with continuous and discrete variables",
%               Report naXys-06-2015, University of Namur (Belgium), 2015.
%
%               N. I. M. Gould, D. Orban and Ph. L. Toint,
%               "CUTEst: a Constrained and Unconstrained Testing Environment
%               with safe threads", Computational Optimization and Applications,
%               Volume 60, Issue 3, pp. 545-557, 2015.

%%  CONDITIONS OF USE

%   Use at your own risk! No guarantee of any kind given or implied.

%   Copyright (c) 2016, Ph. Toint and M. Porcelli. All rights reserved.
%
%   Redistribution and use of the BFO package in source and binary forms, with 
%   or without modification, are permitted provided that the following conditions
%   are met:
%
%    * Redistributions of source code must retain the above copyright notice, 
%      this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright notice, 
%      this list of conditions and the following disclaimer in the documentation
%      and/or other materials provided with the distribution.
%
%   +-------------------------------------------------------------------------+
%   |                                                                         |
%   |                             DISCLAIMER                                  |
%   |                                                                         |
%   |  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    |
%   |  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOR      |
%   |  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS      |
%   |  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE         |
%   |  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,    |
%   |  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,   |
%   |  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS  |
%   |  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND |
%   |  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR  |
%   |  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE |
%   |  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH       |
%   |  DAMAGE.                                                                |
%   |                                                                         |
%   +-------------------------------------------------------------------------+

%  DOCUMENTATION:
----------------------------------------

An extensive description of the use of BFO is given in the header of the
Matlab file ./bfo.m and in the published html page ./bfo_html_pdf/bfo.html.

A copy of the referring manuscript "NTR-06-2015.pdf" is provided in ./bfo_html_pdf/.

% CONTENTS OF THE "BFO-CODE" DIRECTORY:
----------------------------------------

- The solver bfo.m

- Driver test programs: 
  1) test_bfo.m
  2) test_cutest.m
  3) test_equilibrium.m
  4) test_paper_examples.m
  5) test_rcubic_training.m 
  6) test_vbeam_training.m  

- Directory "test_problems" containing the test problems:
  1) the fruity set *.m files and corresponding *_data.m files: orange, kiwi,
     banana, apple, fruit_bowl, etc
  2) the CUTEst problems .SIF files used in the paper located in ./cutest_problems/
  3) the equilibrium problem files: demand.m, benefit.m, satisfaction.m, budget.m

  VBEAM and RCUBIC test problems are generated and (possibly) saved in 
  ./test_problems/vbeam_problems/ and ./test_problems/rcubic_problems/,
  running test_vbeam_training.m and test_rcubic_training.m, respectively.

- Directory "auxiliary_functions" containing:
  1) test_bfo_check.m
  2) compute_performance_history.m
  3) cutest_pblist.m
  5) lcurve.m

- Directory "bfo_html" containing pictures and bfo.html with the published version of 
  bfo.m generated with MATLAB® 7.14

Descriptions of the above .m programs are included at the beginning of each file.
  
% RUNNING TESTS:
----------------------------------------

- Test problems described in the papers can be obtained running the script test_*.m.
  ES:
     >> test_paper_examples
  or
     >> test_vbeam_training

- The output files of all drivers are saved in corresponding directories 
  named ./test_*_output/

- The driver test_bfo.m tests the main program checking many of the possible user argument 
  list combinations.

- Warning: it is possible to run test_cutest.m only if a CUTEst Matlab interface is currently installed.

% DEVELOPMENT HISTORY
----------------------------------------

Version 1.01:
  inclusion of a user-defined search step
  correction of a bug affecting the name of an objective function  after restart

% THE BFO TEAM 
----------------------------------------

Current BFO team:

   Philippe L. Toint, University of Namur, Belgium, e-mail philippe.toint@unamur.be
   Margherita Porcelli, University of Florence, Italy, e-mail margherita.porcelli@unifi.it

	
