/****************************************************************************
 *      session.h: YafaRay Session control
 *      This is part of the yafray package
 *		Copyright (C) 2016 David Bluecame
 * 		Session control and persistent objects between renders
 *
 *      This library is free software; you can redistribute it and/or
 *      modify it under the terms of the GNU Lesser General Public
 *      License as published by the Free Software Foundation; either
 *      version 2.1 of the License, or (at your option) any later version.
 *
 *      This library is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *      Lesser General Public License for more details.
 *
 *      You should have received a copy of the GNU Lesser General Public
 *      License along with this library; if not, write to the Free Software
 *      Foundation,Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */
 
#ifndef Y_SESSION_H
#define Y_SESSION_H

#include <iostream>
#include <ctime>
#include <fstream>
#include <sstream>
#include <string>
#include <core_api/logging.h>
#include <core_api/sysinfo.h>
#if defined(_WIN32) && defined(__MINGW32__)
	#undef _GLIBCXX_HAS_GTHREADS
	#include <utilities/mingw-std-threads/mingw.thread.h>
	#include <mutex>
	#include <utilities/mingw-std-threads/mingw.mutex.h>
	#include <utilities/mingw-std-threads/mingw.condition_variable.h>
#else
	#include <thread>
	#include <mutex>
	#include <condition_variable>
#endif

__BEGIN_YAFRAY

class photonMap_t;

class YAFRAYCORE_EXPORT session_t
{
	public:
		session_t();
		session_t(const session_t&);	//customizing copy constructor so we can use a std::mutex as a class member (not copiable)
		
		~session_t();
				
		void setStatusRenderStarted();
		void setStatusRenderResumed();
		void setStatusRenderFinished();
		void setStatusRenderAborted();
		void setStatusTotalPasses(int total_passes);
		void setStatusCurrentPass(int current_pass);
		void setStatusCurrentPassPercent(float current_pass_percent);
		void setInteractive(bool interactive);
		
		bool renderInProgress();
		bool renderResumed();
		bool renderFinished();
		bool renderAborted();
		int totalPasses();
		int currentPass();
		float currentPassPercent();
		bool isInteractive();
				
		photonMap_t * causticMap = nullptr;
		photonMap_t * diffuseMap = nullptr;
		photonMap_t * radianceMap = nullptr;
		
		std::mutex mutx;
	
	protected:
		bool mRenderInProgress = false;
		bool mRenderFinished = false;
		bool mRenderResumed = false;
		bool mRenderAborted = false;
		int mTotalPasses = 0;
		int mCurrentPass = 0;
		float mCurrentPassPercent = 0.f;
		bool mInteractive = false;
};

extern YAFRAYCORE_EXPORT session_t session;

__END_YAFRAY

#endif
