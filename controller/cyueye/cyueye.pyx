
from __future__ import print_function
from libc.stdlib cimport malloc, free
import numpy as np
cimport numpy as np



cdef extern from 'ueye.h':
    # --- Structs ---
    ctypedef struct IMAGE_FORMAT_INFO:
       int nFormatID
       unsigned int nWidth
       unsigned int nHeight
       int nX0
       int nY0
       unsigned int nSupportedCaptureModes
       unsigned int nBinningMode
       unsigned int nSubsamplingMode
       char strFormatName[64]
       double dSensorScalerFactor
       unsigned int nReserved[22]
    ctypedef struct IMAGE_FORMAT_LIST:
        unsigned int nSizeOfListEntry
        unsigned int nNumListElements
        unsigned int nReserved[4]
        IMAGE_FORMAT_INFO FormatInfo[1]
    # --- Defines ---
    int IS_SET_DM_DIB
        # --- Color Modes
    int IS_CM_SENSOR_RAW16
    int IS_CM_SENSOR_RAW12
    int IS_CM_SENSOR_RAW10
    int IS_CM_SENSOR_RAW8
    int IS_CM_MONO16
    int IS_CM_MONO12
    int IS_CM_MONO10
    int IS_CM_MONO8
    int IS_CM_RGBA12_UNPACKED
    int IS_CM_RGB12_UNPACKED
    int IS_CM_RGB10_UNPACKED
    int IS_CM_RGB10_PACKED
    int IS_CM_RGBA8_PACKED
    int IS_CM_RGBY8_PACKED
    int IS_CM_RGB8_PACKED
    int IS_CM_BGRA12_UNPACKED
    int IS_CM_BGR12_UNPACKED
    int IS_CM_BGR10_UNPACKED
    int IS_CM_BGR10_PACKED
    int IS_CM_BGRA8_PACKED
    int IS_CM_BGRY8_PACKED
    int IS_CM_BGR8_PACKED
    int IS_CM_BGR565_PACKED
    int IS_CM_BGR5_PACKED
    int IS_CM_UYVY_PACKED
    int IS_CM_UYVY_MONO_PACKED
    int IS_CM_UYVY_BAYER_PACKED
    int IS_CM_CBYCRY_PACKED
    # --- Enums ---
    ctypedef enum IMAGE_FORMAT_CMD:
        IMGFRMT_CMD_GET_NUM_ENTRIES = 1
        IMGFRMT_CMD_GET_LIST = 2
        IMGFRMT_CMD_SET_FORMAT = 3
        IMGFRMT_CMD_GET_ARBITORY_AOI_SUPPORTED = 4
        IMGFRMT_CMD_GET_FORMAT_INFO = 5
    ctypedef enum E_EXPOSURE_CMD:
        IS_EXPOSURE_CMD_GET_EXPOSURE = 7
        IS_EXPOSURE_CMD_SET_EXPOSURE = 12
        IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE_MIN = 2
        IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE_MAX = 3
    ctypedef enum E_SATURATION_CMD:
        SATURATION_CMD_GET_VALUE = 1
        SATURATION_CMD_SET_VALUE = 6
    # --- Functions ---
    int is_InitCamera(unsigned int* hcam, void* hwand)
    int is_ExitCamera(unsigned int hcam)
    int is_SetDisplayMode(unsigned int hcam, int mode)
    int is_SetColorMode(unsigned int hcam, int mode)
    int is_AllocImageMem(unsigned int hcam, int width, int height, int bitspixel, char** ppcImgMem, int* pid)
    int is_ImageFormat(unsigned int hcam, unsigned int ncommand, void *pParam, unsigned int nsizeofparam)
    int is_SetImageMem(unsigned int hcam, char* pcImageMem, int pid_id)
    int is_FreezeVideo(unsigned int hcam, int wait)
    int is_GetImageMemPitch(unsigned int hcam, int* pitch)
    int is_CaptureVideo(unsigned int hcam, int wait)
    int is_FreeImageMem(unsigned int hcam, char* pcImageMem, int pid)
    int is_Exposure(unsigned int hcam, unsigned int nCommand, void *pParam, unsigned int cbSizeOfParam)
    int is_SetFrameRate(unsigned int hcam, double FPS, double *newFPS)
    int is_Saturation(unsigned int hcam, unsigned int nCommand, void *pParam, unsigned int nSizeOfParam)
    int is_SetSaturation(unsigned int hcam, int ChromU, int ChromV)

cdef class Cam:
    cdef:
        unsigned int hCam
        int pid
        char *pcImgMem
        str displaymode
        str colormode
        int bitspixel
        int width
        int height
        int format_id
        IMAGE_FORMAT_LIST* image_format_list
        cdef np.npy_intp dims[3]
    def __cinit__(self, format_id, hcam=0, displaymode='dib', colormode="bgr8_packed"):
        self.hCam = hcam
        self._init_camera()
        self.get_supported_formats()
        self.displaymode=displaymode
        self.colormode=colormode
        self.set_display_mode("dib")
        self.set_color_mode(self.colormode)
        self.format_id = format_id
        self.set_format(self.format_id)
        self.alloc_image_mem()
        np.Py_INCREF(np.NPY_UINT8)
        np.import_array()
    def __dealloc__(self):
        self.free_image_mem()
        self.exit_camera()

    def _check_deamon(self):
        pass


    def _init_camera(self):
        ret = is_InitCamera(&self.hCam, NULL)
        print("Status init_Camera: ", ret)
        return ret

    def exit_camera(self):
        ret = is_ExitCamera(self.hCam)
        print("Status exit_camera: ", ret)
        return ret

    def set_display_mode(self, mode):
        if mode is 'dib':
            ret = is_SetDisplayMode(self.hCam, IS_SET_DM_DIB)
        else:
            raise ValueError(mode, " is not supported")
        print("Status set_display_moded: ", ret)

    def set_color_mode(self, mode):

        class color_mode_options():
            def __init__(self, ueye_camera_mode, bitspixel):
                self.ueye_camera_mode = ueye_camera_mode
                self.bitspixel = bitspixel

        options = {
            'bgr8_packed': color_mode_options(IS_CM_BGR8_PACKED, 24)
        }


        if mode in options:
            ret = is_SetColorMode(self.hCam, options[mode].ueye_camera_mode)
            self.bitspixel = options[mode].bitspixel
        else:
            raise ValueError(mode, " is no colormode")
        print("Status set_color_mode: ", ret)
        return ret

    def set_format(self, int format_id):
        cdef unsigned int i
        cdef IMAGE_FORMAT_INFO format_info
        for i in range(self.image_format_list.nNumListElements):
            format_info = self.image_format_list.FormatInfo[i]
            if format_id is format_info.nFormatID:
                ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_SET_FORMAT, &format_id, 4)
                print("Status set_format: ", ret)
                self.height = format_info.nHeight
                self.width = format_info.nWidth
                return ret
        raise ValueError("Format: ", format_id, "is not supported on your camera")

    def get_supported_formats(self):
        cdef unsigned int count
        cdef unsigned int bytesneeded = sizeof(IMAGE_FORMAT_LIST)
        ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_GET_NUM_ENTRIES, &count, sizeof(count))
        bytesneeded += (count - 1) * sizeof(IMAGE_FORMAT_INFO)
        cdef void* ptr
        ptr = malloc(bytesneeded)
        cdef IMAGE_FORMAT_LIST* pformatList = <IMAGE_FORMAT_LIST *> ptr
        pformatList.nSizeOfListEntry = sizeof(IMAGE_FORMAT_INFO)
        pformatList.nNumListElements = count
        ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_GET_LIST, pformatList, bytesneeded)
        cdef unsigned int i, n = pformatList.nNumListElements
        cdef IMAGE_FORMAT_INFO formatInfo
        self.image_format_list = pformatList
        print("Status get_supported_formats", ret)
        return ret


    def alloc_image_mem(self):
        ret = is_AllocImageMem(self.hCam, self.width, self.height, self.bitspixel, &self.pcImgMem, &self.pid)
        print("Status alloc_image_mem: ", ret)
        ret = self.set_image_mem()
        cdef int colorspace = ((self.bitspixel+7)/8)
        self.dims[0]=self.height
        self.dims[1]=self.width
        self.dims[2]=colorspace
        return ret

    def free_image_mem(self):
        ret = is_FreeImageMem(self.hCam, self.pcImgMem, self.pid)
        print('Status free_image_mem: ', ret)

    def set_image_mem(self):
        ret = is_SetImageMem(self.hCam, self.pcImgMem, self.pid)
        print("Status set_image_mem: ", ret)

    def freeze_video(self):
        ret = is_FreezeVideo(self.hCam, 1)

    def capture_video(self):
        ret = is_CaptureVideo(self.hCam, 0)

    def freeze_to_numpy(self):
        self.freeze_video()
        return np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)

    def video_to_numpy(self):
        return np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)

    def set_exposure(self, double exposure):
        ret = is_Exposure(self.hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &exposure, 8)
        print(ret)
        return ret

    def get_exposure(self):
        cdef double exposure
        ret = is_Exposure(self.hCam, IS_EXPOSURE_CMD_GET_EXPOSURE, &exposure, 8)
        return exposure

    def set_framerate(self, double framerate):
        cdef double new_framrate
        ret = is_SetFrameRate(self.hCam, framerate, &new_framrate)
        return new_framrate, ret

    def set_saturation(self, int saturation):
       ret = is_SetSaturation(self.hCam, saturation, saturation)
       return ret

    def get_saturation(self):
        pass

    def get_widht(self):
        return self.width

    def get_height(self):
        return self.height

    #Horus help functions
    def read(self):
        self.freeze_video()
        return True, np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)

    def grab(self):
        return np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)
