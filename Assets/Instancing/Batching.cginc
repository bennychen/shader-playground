// The include for the batching
#if !defined (BATCHING_INCLUDE)
#define BATCHING_INCLUDE

// Input Defines:
//		BATCHING_OBJECT_NUMBER_X: The x should be replaced with the number of matrices used in the batching
// Output Defines
//		BATCHING_OBJECT_NUMBER: will be the number of objects used for the batching
#ifdef BATCHING_OBJECT_NUMBER_1
	#define BATCHING_OBJECT_NUMBER 1
#elif defined (BATCHING_OBJECT_NUMBER_2)
	#define BATCHING_OBJECT_NUMBER 2
#elif defined (BATCHING_OBJECT_NUMBER_3)
	#define BATCHING_OBJECT_NUMBER 3
#elif defined (BATCHING_OBJECT_NUMBER_4)
	#define BATCHING_OBJECT_NUMBER 4
#elif defined (BATCHING_OBJECT_NUMBER_5)
	#define BATCHING_OBJECT_NUMBER 5
#elif defined (BATCHING_OBJECT_NUMBER_6)
	#define BATCHING_OBJECT_NUMBER 6
#elif defined (BATCHING_OBJECT_NUMBER_7)
	#define BATCHING_OBJECT_NUMBER 7
#elif defined (BATCHING_OBJECT_NUMBER_8)
	#define BATCHING_OBJECT_NUMBER 8
#elif defined (BATCHING_OBJECT_NUMBER_9)
	#define BATCHING_OBJECT_NUMBER 9
#else 
	#error Invalid batching number.
#endif

uniform float4x4 ModelMatrix0;
uniform float4x4 ModelMatrix1;
uniform float4x4 ModelMatrix2;
uniform float4x4 ModelMatrix3;
uniform float4x4 ModelMatrix4;
uniform float4x4 ModelMatrix5;
uniform float4x4 ModelMatrix6;
uniform float4x4 ModelMatrix7;
uniform float4x4 ModelMatrix8;

// This should be used to get the matrix for the given vertex
inline float4x4 GetMatrix(float selector)
{
	#if BATCHING_OBJECT_NUMBER > 0
		if (selector < 0.5) return ModelMatrix0;
	#endif
	#if BATCHING_OBJECT_NUMBER > 1
		else if (selector < 1.5) return ModelMatrix1;
	#endif
	#if BATCHING_OBJECT_NUMBER > 2
		else if (selector < 2.5) return ModelMatrix2;
	#endif
	#if BATCHING_OBJECT_NUMBER > 3
		else if (selector < 3.5) return ModelMatrix3;
	#endif
	#if BATCHING_OBJECT_NUMBER > 4
		else if (selector < 4.5) return ModelMatrix4;
	#endif
	#if BATCHING_OBJECT_NUMBER > 5
		else if (selector < 5.5) return ModelMatrix5;
	#endif
	#if BATCHING_OBJECT_NUMBER > 6
		else if (selector < 6.5) return ModelMatrix6;
	#endif
	#if BATCHING_OBJECT_NUMBER > 7
		else if (selector < 7.5) return ModelMatrix7;
	#endif
	#if BATCHING_OBJECT_NUMBER > 8
		else if (selector < 8.5) return ModelMatrix8;
	#endif
	
	return ModelMatrix0;
}

#endif //BATCHING_INCLUDE